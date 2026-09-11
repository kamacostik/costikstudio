import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignageHotelProfile extends Equatable {
  const SignageHotelProfile({
    this.id,
    this.name = '',
    this.address = '',
    this.description = '',
    this.logoUrl = '',
  });

  final String? id;
  final String name;
  final String address;
  final String description;
  final String logoUrl;

  factory SignageHotelProfile.fromMap(Map<String, dynamic> map) {
    return SignageHotelProfile(
      id: map['id'] as String?,
      name: map['nama_hotel'] as String? ?? '',
      address: map['alamat_hotel'] as String? ?? '',
      description: map['keterangan_hotel'] as String? ?? '',
      logoUrl: map['logo_hotel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toUpsertMap({required String tenantId}) {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'tenant_id': tenantId,
      'nama_hotel': name,
      'alamat_hotel': address,
      'keterangan_hotel': description,
      'logo_hotel': logoUrl,
    };
  }

  @override
  List<Object?> get props => [id, name, address, description, logoUrl];
}

class SignageDevice extends Equatable {
  const SignageDevice({
    required this.id,
    required this.name,
    required this.isVideo,
    required this.isPromo,
    required this.promoDuration,
    required this.tableColumn,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isVideo;
  final bool isPromo;
  final double promoDuration;
  final int tableColumn;
  final bool isActive;

  factory SignageDevice.fromMap(Map<String, dynamic> map) {
    return SignageDevice(
      id: map['id'] as String,
      name: map['nama_device'] as String? ?? 'Unnamed Device',
      isVideo: map['is_video'] as bool? ?? true,
      isPromo: map['is_promo'] as bool? ?? true,
      promoDuration: (map['promo_duration'] as num?)?.toDouble() ?? 20,
      tableColumn: map['table_column'] as int? ?? 4,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    isVideo,
    isPromo,
    promoDuration,
    tableColumn,
    isActive,
  ];
}

abstract class SignageAdminRepository {
  const SignageAdminRepository();

  Future<String?> currentTenantId();
  Future<SignageHotelProfile?> fetchHotelProfile();
  Future<SignageHotelProfile> saveHotelProfile(SignageHotelProfile profile);
  Future<List<SignageDevice>> fetchDevices();
}

class SupabaseSignageAdminRepository extends SignageAdminRepository {
  const SupabaseSignageAdminRepository({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @override
  Future<String?> currentTenantId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _supabase
        .from('sg_profiles')
        .select('tenant_id')
        .eq('id', userId)
        .maybeSingle();
    return row?['tenant_id'] as String?;
  }

  @override
  Future<SignageHotelProfile?> fetchHotelProfile() async {
    final tenantId = await currentTenantId();
    if (tenantId == null) return null;

    final row = await _supabase
        .from('sg_hotel_profiles')
        .select()
        .eq('tenant_id', tenantId)
        .maybeSingle();
    return row == null ? null : SignageHotelProfile.fromMap(row);
  }

  @override
  Future<SignageHotelProfile> saveHotelProfile(
    SignageHotelProfile profile,
  ) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) {
      throw StateError(
        'Tenant Signage belum tersedia. Jalankan Siapkan Tenant dulu.',
      );
    }

    final rows = await _supabase
        .from('sg_hotel_profiles')
        .upsert(profile.toUpsertMap(tenantId: tenantId))
        .select()
        .limit(1);
    if (rows.isEmpty) return profile;
    return SignageHotelProfile.fromMap(rows.first);
  }

  @override
  Future<List<SignageDevice>> fetchDevices() async {
    final tenantId = await currentTenantId();
    if (tenantId == null) return const [];

    final rows = await _supabase
        .from('sg_devices')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at');
    return rows.map(SignageDevice.fromMap).toList();
  }
}
