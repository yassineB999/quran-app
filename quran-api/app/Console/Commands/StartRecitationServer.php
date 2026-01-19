<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use React\EventLoop\Loop;
use React\Socket\SocketServer;
use React\Socket\ConnectionInterface;
use Ratchet\RFC6455\Messaging\MessageBuffer;
use Ratchet\RFC6455\Messaging\Frame;
use Ratchet\RFC6455\Handshake\ServerNegotiator;
use Ratchet\RFC6455\Handshake\RequestVerifier;

class StartRecitationServer extends Command
{
    protected $signature = 'recitation:serve {--port=6001} {--host=0.0.0.0}';
    protected $description = 'Start the WebSocket Proxy Server using ReactPHP (Reverb Dependencies)';

    protected $clients = [];

    public function handle()
    {
        $port = $this->option('port');
        $host = $this->option('host');
        $this->info("Starting Proxy Server on {$host}:{$port}");

        $apiKey = env('QURANI_API_KEY');
        if (empty($apiKey)) {
            $this->error("QURANI_API_KEY is missing in .env");
            return 1;
        }

        $loop = Loop::get();
        // Create Raw TCP Server
        $socket = new SocketServer("{$host}:{$port}", [], $loop);

        $socket->on('connection', function (ConnectionInterface $conn) use ($loop) {
            $this->info("New connection from {$conn->getRemoteAddress()}");

            // We need to handle WebSocket Handshake manually since we don't have IoServer
            $buffer = '';

            $conn->on('data', function ($data) use ($conn, &$buffer) {
                // Check if already handshaked/client exists
                if (!isset($this->clients[(int)$conn->stream])) {
                    $buffer .= $data;
                    if (strpos($buffer, "\r\n\r\n") !== false) {
                        // Attempt Handshake
                        if ($this->performHandshake($conn, $buffer)) {
                            $buffer = ''; // Clear buffer, rest handled by MessageBuffer
                        } else {
                            $conn->close();
                        }
                    }
                } else {
                    // Feed data to RFC6455 MessageBuffer
                    $this->clients[(int)$conn->stream]['message_buffer']->onData($data);
                }
            });

            $conn->on('close', function () use ($conn) {
                $this->cleanupClient((int)$conn->stream);
            });

            $conn->on('error', function ($e) use ($conn) {
                $this->error("Connection Error: " . $e->getMessage());
                $conn->close();
            });
        });

        $this->info("Server Running. Press Ctrl+C to stop.");
        $loop->run();
    }

    protected function performHandshake($conn, $headerParams)
    {
        $headers = [];
        foreach (explode("\r\n", $headerParams) as $line) {
            if (strpos($line, ': ') !== false) {
                [$k, $v] = explode(': ', $line, 2);
                $headers[strtolower($k)] = $v;
            }
        }

        if (!isset($headers['sec-websocket-key'])) return false;

        $key = $headers['sec-websocket-key'];
        $accept = base64_encode(sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11', true));

        $response = "HTTP/1.1 101 Switching Protocols\r\n" .
            "Upgrade: websocket\r\n" .
            "Connection: Upgrade\r\n" .
            "Sec-WebSocket-Accept: {$accept}\r\n\r\n";

        $conn->write($response);

        // Init Client State
        $this->clients[(int)$conn->stream] = [
            'conn' => $conn,
            'qurani_conn' => null,
            'qurani_ready' => false,  // True after start_tilawa_session is sent
            'pending_messages' => [], // Buffer for messages before Qurani is ready
            'message_buffer' => new MessageBuffer(
                new \Ratchet\RFC6455\Messaging\CloseFrameChecker,
                function (\Ratchet\RFC6455\Messaging\MessageInterface $msg) use ($conn) {
                    $this->onClientMessage((int)$conn->stream, $msg);
                },
                function ($frame) {}, // Control frames
                true // Expect masked (Client->Server)
            )
        ];

        // Handle any extra data in buffer if packet contained body? 
        // (Usually handshake is separate, but good robust logic would check)
        return true;
    }

    protected function onClientMessage($clientId, $msg)
    {
        $session = $this->clients[$clientId] ?? null;
        if (!$session) return;

        $quraniConn = $session['qurani_conn'];
        $quraniReady = $session['qurani_ready'] ?? false;
        $isBinary = $msg->isBinary();
        $payloadSize = strlen($msg->getPayload());

        if ($quraniConn && $quraniReady) {
            // Forward to Qurani - connection is ready!
            if ($isBinary) {
                $this->info("Client $clientId -> Qurani: Binary audio chunk ($payloadSize bytes)");
            } else {
                $this->info("Client $clientId -> Qurani: Text message ($payloadSize bytes)");
            }

            $frame = new Frame($msg->getPayload(), true, $isBinary ? Frame::OP_BINARY : Frame::OP_TEXT);
            $frame->maskPayload();
            $quraniConn->write($frame->getContents());
        } else if ($quraniConn && !$quraniReady) {
            // Qurani connected but not ready yet - buffer the message
            $this->info("Client $clientId: Buffering message ($payloadSize bytes) - waiting for session start");
            $this->clients[$clientId]['pending_messages'][] = $msg;
        } else {
            // No Qurani connection yet
            $payload = $msg->getPayload();
            $json = json_decode($payload, true);

            if ($json && isset($json['method']) && $json['method'] === 'StartTilawaSession') {
                $this->info("Client $clientId: StartTilawaSession received");
                $this->connectToQurani($clientId, $payload);
            } else {
                // Buffer messages until we have a Qurani connection
                $this->info("Client $clientId: Buffering early message ($payloadSize bytes)");
                $this->clients[$clientId]['pending_messages'][] = $msg;
            }
        }
    }

    protected function connectToQurani($clientId, $startPayload)
    {
        $apiKey = env('QURANI_API_KEY');
        $connector = new \React\Socket\Connector();

        $this->info("Connecting Client {$clientId} to Qurani.ai...");

        $connector->connect('tls://api.qurani.ai:443')->then(function (ConnectionInterface $conn) use ($clientId, $startPayload, $apiKey) {
            $this->info("TCP Connected to Qurani.ai");

            // Perform Client Handshake
            $key = base64_encode(random_bytes(16));
            $req = "GET /?api_key={$apiKey} HTTP/1.1\r\n" .
                "Host: api.qurani.ai\r\n" .
                "Upgrade: websocket\r\n" .
                "Connection: Upgrade\r\n" .
                "Sec-WebSocket-Key: {$key}\r\n" .
                "Sec-WebSocket-Version: 13\r\n\r\n";

            $conn->write($req);

            // Buffer for Qurani
            $qBuffer = new MessageBuffer(
                new \Ratchet\RFC6455\Messaging\CloseFrameChecker,
                function ($msg) use ($clientId) {
                    // Qurani (Server) -> Proxy (Client). Received Unmasked.
                    // Forward Proxy -> Flutter (Server -> Client). Send Unmasked.
                    $this->sendToClient($clientId, $msg->getPayload(), $msg->isBinary());
                },
                function ($frame) {},
                false // Expect Unmasked from Server
            );

            // Handshake State
            $state = ['handshaked' => false, 'buffer' => ''];

            $conn->on('data', function ($data) use ($conn, &$state, $qBuffer, $clientId, $startPayload) {
                if (!$state['handshaked']) {
                    $state['buffer'] .= $data;
                    if (strpos($state['buffer'], "\r\n\r\n") !== false) {
                        if (strpos($state['buffer'], '101 Switching Protocols') !== false) {
                            $state['handshaked'] = true;
                            $this->info("Qurani WS Handshake Success (Client $clientId)");

                            if (isset($this->clients[$clientId])) {
                                $this->clients[$clientId]['qurani_conn'] = $conn;
                                $this->clients[$clientId]['qurani_buffer'] = $qBuffer; // Keep ref to prevent GC

                                // Send Start Payload
                                $frame = new Frame($startPayload, true, Frame::OP_TEXT); // Masked
                                $frame->maskPayload();
                                $conn->write($frame->getContents());

                                // Mark as ready and flush buffered messages
                                $this->clients[$clientId]['qurani_ready'] = true;
                                $pending = $this->clients[$clientId]['pending_messages'] ?? [];
                                $this->clients[$clientId]['pending_messages'] = [];

                                if (count($pending) > 0) {
                                    $this->info("Flushing " . count($pending) . " buffered messages for Client $clientId");
                                    foreach ($pending as $bufferedMsg) {
                                        $isBinary = $bufferedMsg->isBinary();
                                        $bufferedFrame = new Frame($bufferedMsg->getPayload(), true, $isBinary ? Frame::OP_BINARY : Frame::OP_TEXT);
                                        $bufferedFrame->maskPayload();
                                        $conn->write($bufferedFrame->getContents());
                                    }
                                }
                            } else {
                                $conn->close();
                            }

                            // Process leftover
                            $rest = substr($state['buffer'], strpos($state['buffer'], "\r\n\r\n") + 4);
                            if (strlen($rest) > 0) $qBuffer->onData($rest);
                        } else {
                            $this->error("Qurani Handshake Failed");
                            $conn->close();
                        }
                    }
                } else {
                    $qBuffer->onData($data);
                }
            });

            $conn->on('close', function () use ($clientId) {
                $this->info("Qurani Closed connection for $clientId");
                // Maybe close client?
                $this->cleanupClient($clientId);
            });
        }, function ($e) use ($clientId) {
            $this->error("Qurani Connection Failed: " . $e->getMessage());
            $this->sendToClient($clientId, json_encode(['error' => 'AI Connection Failed']));
        });
    }

    protected function sendToClient($clientId, $data, $binary = false)
    {
        if (isset($this->clients[$clientId])) {
            $conn = $this->clients[$clientId]['conn'];
            $frame = new Frame($data, false, $binary ? Frame::OP_BINARY : Frame::OP_TEXT);
            $conn->write($frame->getContents());
        }
    }

    protected function cleanupClient($clientId)
    {
        if (isset($this->clients[$clientId])) {
            $c = $this->clients[$clientId];
            // Close Qurani
            if (isset($c['qurani_conn'])) $c['qurani_conn']->close();
            unset($this->clients[$clientId]);
        }
    }
}
