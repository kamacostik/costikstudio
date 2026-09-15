import 'package:supabase_flutter/supabase_flutter.dart';

/// One Signage tenant row for the admin tenant list.
class AdminSignageTenant {
  const AdminSignageTenant({
    required this.tenantId,
    required this.tenantName,
    this.customerUserId,
    this.customerEmail,
    this.customerName = '',
    this.subscriptionStatus,
    this.subscriptionDeviceCount,
    this.subscriptionExpiresAt,
    this.deviceTotal = 0,
    this.deviceActive = 0,
  });

  final String tenantId;
  final String tenantName;
  final String? customerUserId;
  final String? customerEmail;
  final String customerName;
  final String? subscriptionStatus;
  final int? subscriptionDeviceCount;
  final DateTime? subscriptionExpiresAt;
  final int deviceTotal;
  final int deviceActive;

  factory AdminSignageTenant.fromMap(Map<String, dynamic> map) {
    return AdminSignageTenant(
      tenantId: '${map['tenant_id'] ?? ''}',
      tenantName: '${map['tenant_name'] ?? 'Unnamed Tenant'}',
      customerUserId: map['customer_user_id']?.toString(),
      customerEmail: map['customer_email']?.toString(),
      customerName: '${map['customer_name'] ?? ''}',
      subscriptionStatus: map['subscription_status']?.toString(),
      subscriptionDeviceCount: (map['subscription_device_count'] as num?)
          ?.toInt(),
      subscriptionExpiresAt: DateTime.tryParse(
        '${map['subscription_expires_at'] ?? ''}',
      ),
      deviceTotal: (map['device_total'] as num?)?.toInt() ?? 0,
      deviceActive: (map['device_active'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract class AdminSignageRepository {
  Future<List<AdminSignageTenant>> loadTenants();
}

class SupabaseAdminSignageRepository implements AdminSignageRepository {
  const SupabaseAdminSignageRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  @override
  Future<List<AdminSignageTenant>> loadTenants() async {
    final response = await _supabase.rpc('admin_list_signage_tenants');
    if (response is! List) return const [];
    return response
        .whereType<Map<String, dynamic>>()
        .map(AdminSignageTenant.fromMap)
        .toList();
  }
}

class DummyAdminSignageRepository implements AdminSignageRepository {
  @override
  Future<List<AdminSignageTenant>> loadTenants() async {
    return [
      AdminSignageTenant(
        tenantId: 'tenant-kendari-hotel',
        tenantName: 'Kendari Hotel Group',
        customerUserId: 'user-kendari',
        customerEmail: 'admin@kendarihotel.com',
        customerName: 'Kendari Hotel Group',
        subscriptionStatus: 'active',
        subscriptionDeviceCount: 25,
        subscriptionExpiresAt: DateTime(2026, 10, 1),
        deviceTotal: 18,
        deviceActive: 16,
      ),
      AdminSignageTenant(
        tenantId: 'tenant-demo',
        tenantName: 'Demo Customer',
        customerUserId: 'demo-user',
        customerEmail: 'user@costik.com',
        customerName: 'Demo Customer',
        subscriptionStatus: 'active',
        subscriptionDeviceCount: 5,
        subscriptionExpiresAt: DateTime(2026, 10, 5),
        deviceTotal: 3,
        deviceActive: 3,
      ),
    ];
  }
}
