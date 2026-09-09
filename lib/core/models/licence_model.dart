import 'package:equatable/equatable.dart';

class LicenceModel extends Equatable {
  const LicenceModel({
    required this.id,
    this.userId,
    this.startDate,
    this.expiredDate,
    this.deviceCount = 0,
    this.createdAt,
  });

  factory LicenceModel.fromJson(Map<String, dynamic> json) {
    return LicenceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      expiredDate: json['expired_date'] != null
          ? DateTime.parse(json['expired_date'] as String)
          : null,
      deviceCount: (json['device_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  final String id;
  final String? userId;
  final DateTime? startDate;
  final DateTime? expiredDate;
  final int deviceCount;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate?.toIso8601String(),
      'expired_date': expiredDate?.toIso8601String(),
      'device_count': deviceCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  LicenceModel copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? expiredDate,
    int? deviceCount,
    DateTime? createdAt,
  }) {
    return LicenceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      expiredDate: expiredDate ?? this.expiredDate,
      deviceCount: deviceCount ?? this.deviceCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    startDate,
    expiredDate,
    deviceCount,
    createdAt,
  ];
}
