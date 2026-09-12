import 'package:costikstudio/features/signage/data/signage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSignageRepository implements SignageRepository {
  const SupabaseSignageRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  @override
  Future<SignageTenant?> fetchCurrentTenant() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _supabase
        .from('sg_profiles')
        .select('id, tenant_id, sg_tenants!inner(name)')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;

    final tenant = row['sg_tenants'];
    final tenantName = tenant is Map
        ? tenant['name'] as String?
        : 'Costik Signage Tenant';

    return SignageTenant(
      tenantId: row['tenant_id'] as String,
      profileId: row['id'] as String,
      tenantName: tenantName ?? 'Costik Signage Tenant',
    );
  }

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
