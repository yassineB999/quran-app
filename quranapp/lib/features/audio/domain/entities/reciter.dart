import 'package:equatable/equatable.dart';

/// Represents a Quran reciter entity
class Reciter extends Equatable {
  final int id;
  final String name;
  final String rewaya;
  final String serverUrl;

  const Reciter({
    required this.id,
    required this.name,
    required this.rewaya,
    required this.serverUrl,
  });

  @override
  List<Object?> get props => [id, name, rewaya, serverUrl];
}
