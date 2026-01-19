import 'package:quranapp/features/audio/domain/entities/reciter.dart';

/// Model for Reciter with JSON serialization
class ReciterModel extends Reciter {
  const ReciterModel({
    required super.id,
    required super.name,
    required super.rewaya,
    required super.serverUrl,
  });

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    return ReciterModel(
      id: json['reciter_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      rewaya: json['rewaya'] ?? '',
      serverUrl: json['server_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reciter_id': id,
      'name': name,
      'rewaya': rewaya,
      'server_url': serverUrl,
    };
  }
}
