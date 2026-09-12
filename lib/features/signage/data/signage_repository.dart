import 'package:equatable/equatable.dart';

class SignageTenant extends Equatable {
  const SignageTenant({
    required this.tenantId,
    required this.profileId,
    required this.tenantName,
  });

  final String tenantId;
  final String profileId;
  final String tenantName;

  @override
  List<Object?> get props => [tenantId, profileId, tenantName];
}

abstract class SignageRepository {
  Future<SignageTenant?> fetchCurrentTenant();
  Future<SignageTenant> provisionTenant();
}
