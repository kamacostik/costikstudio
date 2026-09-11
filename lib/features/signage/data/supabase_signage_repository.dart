import 'package:costikstudio/features/signage/data/signage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSignageRepository implements SignageRepository {
  const SupabaseSignageRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  @override
  Future<SignageTenant> provisionTenant() async {
    final response = await _supabase.rpc('provision_signage_tenant');
    if (response is! List || response.isEmpty) {
      throw StateError('Provisioning tenant signage gagal.');
    }

    final row = Map<String, dynamic>.from(response.first as Map);
    return SignageTenant(
      tenantId: row['tenant_id'] as String,
      profileId: row['profile_id'] as String,
      tenantName: row['tenant_name'] as String? ?? 'Costik Signage Tenant',
    );
  }
}
