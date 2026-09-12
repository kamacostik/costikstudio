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
    this.pairingCode,
    this.pairingExpiresAt,
    this.activatedAt,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final bool isVideo;
  final bool isPromo;
  final double promoDuration;
  final int tableColumn;
  final bool isActive;
  final String? pairingCode;
  final DateTime? pairingExpiresAt;
  final DateTime? activatedAt;
  final DateTime? lastSeenAt;

  bool get isConnected => activatedAt != null;
  bool get isWaitingPairing =>
      !isConnected &&
      pairingCode != null &&
      pairingExpiresAt != null &&
      pairingExpiresAt!.isAfter(DateTime.now());
  bool get isPairingExpired =>
      !isConnected &&
      pairingExpiresAt != null &&
      !pairingExpiresAt!.isAfter(DateTime.now());

  factory SignageDevice.fromMap(Map<String, dynamic> map) {
    return SignageDevice(
      id: map['id'] as String,
      name: map['nama_device'] as String? ?? 'Unnamed Device',
      isVideo: map['is_video'] as bool? ?? true,
      isPromo: map['is_promo'] as bool? ?? true,
      promoDuration: (map['promo_duration'] as num?)?.toDouble() ?? 20,
      tableColumn: map['table_column'] as int? ?? 4,
      isActive: map['is_active'] as bool? ?? true,
      pairingCode: map['pairing_code'] as String?,
      pairingExpiresAt: DateTime.tryParse(
        map['pairing_expires_at'] as String? ?? '',
      ),
      activatedAt: DateTime.tryParse(map['activated_at'] as String? ?? ''),
      lastSeenAt: DateTime.tryParse(map['last_seen_at'] as String? ?? ''),
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
    pairingCode,
    pairingExpiresAt,
    activatedAt,
    lastSeenAt,
  ];
}

class SignageMediaItem extends Equatable {
  const SignageMediaItem({
    this.id,
    required this.fileName,
    required this.storagePath,
    this.mediaType = 'image',
    this.publicUrl,
  });

  final String? id;
  final String fileName;
  final String storagePath;
  final String mediaType;
  final String? publicUrl;

  factory SignageMediaItem.fromMap(Map<String, dynamic> map) {
    return SignageMediaItem(
      id: map['id'] as String?,
      fileName: map['file_name'] as String? ?? 'Media',
      storagePath: map['storage_path'] as String? ?? '',
      mediaType: map['media_type'] as String? ?? 'image',
      publicUrl: map['public_url'] as String?,
    );
  }

  Map<String, dynamic> toUpsertMap({required String tenantId}) {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'tenant_id': tenantId,
      'bucket': 'signage-media',
      'file_name': fileName,
      'storage_path': storagePath,
      'media_type': mediaType,
      'public_url': publicUrl,
    };
  }

  @override
  List<Object?> get props => [id, fileName, storagePath, mediaType, publicUrl];
}

class SignagePlaylistItem extends Equatable {
  const SignagePlaylistItem({
    this.id,
    required this.name,
    this.mediaId,
    this.path,
    this.isEnabled = true,
  });

  final String? id;
  final String name;
  final String? mediaId;
  final String? path;
  final bool isEnabled;

  factory SignagePlaylistItem.fromMap(Map<String, dynamic> map) {
    return SignagePlaylistItem(
      id: map['id'] as String?,
      name: map['nama_playlist'] as String? ?? 'Playlist',
      mediaId: map['media_id'] as String?,
      path: map['path_playlist'] as String?,
      isEnabled: map['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toUpsertMap({required String tenantId}) {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'tenant_id': tenantId,
      'nama_playlist': name,
      'media_id': mediaId,
      'path_playlist': path,
      'is_enabled': isEnabled,
    };
  }

  @override
  List<Object?> get props => [id, name, mediaId, path, isEnabled];
}

class SignageEventItem extends Equatable {
  const SignageEventItem({
    this.id,
    required this.eventName,
    required this.meetingRoom,
    this.floor = '',
    this.direction = 'right',
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  final String? id;
  final String eventName;
  final String meetingRoom;
  final String floor;
  final String direction;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  factory SignageEventItem.fromMap(Map<String, dynamic> map) {
    return SignageEventItem(
      id: map['id'] as String?,
      eventName: map['event_name'] as String? ?? 'Event',
      meetingRoom: map['meeting_room'] as String? ?? '',
      floor: map['floor'] as String? ?? '',
      direction: map['direction'] as String? ?? 'right',
      startDate: DateTime.tryParse(map['start_date'] as String? ?? ''),
      endDate: DateTime.tryParse(map['end_date'] as String? ?? ''),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toUpsertMap({required String tenantId}) {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'tenant_id': tenantId,
      'event_name': eventName,
      'meeting_room': meetingRoom,
      'floor': floor,
      'direction': direction,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
    id,
    eventName,
    meetingRoom,
    floor,
    direction,
    startDate,
    endDate,
    isActive,
  ];
}

class SignageDevicePairing extends Equatable {
  const SignageDevicePairing({
    required this.deviceId,
    required this.pairingCode,
    required this.expiresAt,
  });

  final String deviceId;
  final String pairingCode;
  final DateTime expiresAt;

  factory SignageDevicePairing.fromMap(Map<String, dynamic> map) {
    return SignageDevicePairing(
      deviceId: map['device_id'] as String,
      pairingCode: map['pairing_code'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  @override
  List<Object?> get props => [deviceId, pairingCode, expiresAt];
}

abstract class SignageAdminRepository {
  const SignageAdminRepository();

  Future<String?> currentTenantId();
  Future<SignageHotelProfile?> fetchHotelProfile();
  Future<SignageHotelProfile> saveHotelProfile(SignageHotelProfile profile);
  Future<List<SignageDevice>> fetchDevices();
  Future<List<SignageMediaItem>> fetchMedia();
  Future<SignageMediaItem> saveMedia(SignageMediaItem item);
  Future<List<SignagePlaylistItem>> fetchPlaylists();
  Future<SignagePlaylistItem> savePlaylist(SignagePlaylistItem item);
  Future<List<SignageEventItem>> fetchEvents();
  Future<SignageEventItem> saveEvent(SignageEventItem item);
  Future<SignageDevicePairing> createDevicePairing({String? deviceName});
  Future<SignageDevicePairing> regenerateDevicePairing(String deviceId);
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
  Future<List<SignageMediaItem>> fetchMedia() async {
    final tenantId = await currentTenantId();
    if (tenantId == null) return const [];
    final rows = await _supabase
        .from('sg_media')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at');
    return rows.map(SignageMediaItem.fromMap).toList();
  }

  @override
  Future<SignageMediaItem> saveMedia(SignageMediaItem item) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) throw StateError('Tenant Signage belum tersedia.');
    final rows = await _supabase
        .from('sg_media')
        .upsert(item.toUpsertMap(tenantId: tenantId))
        .select()
        .limit(1);
    return rows.isEmpty ? item : SignageMediaItem.fromMap(rows.first);
  }

  @override
  Future<List<SignagePlaylistItem>> fetchPlaylists() async {
    final tenantId = await currentTenantId();
    if (tenantId == null) return const [];
    final rows = await _supabase
        .from('sg_playlists')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at');
    return rows.map(SignagePlaylistItem.fromMap).toList();
  }

  @override
  Future<SignagePlaylistItem> savePlaylist(SignagePlaylistItem item) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) throw StateError('Tenant Signage belum tersedia.');
    final rows = await _supabase
        .from('sg_playlists')
        .upsert(item.toUpsertMap(tenantId: tenantId))
        .select()
        .limit(1);
    return rows.isEmpty ? item : SignagePlaylistItem.fromMap(rows.first);
  }

  @override
  Future<List<SignageEventItem>> fetchEvents() async {
    final tenantId = await currentTenantId();
    if (tenantId == null) return const [];
    final rows = await _supabase
        .from('sg_event_lists')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at');
    return rows.map(SignageEventItem.fromMap).toList();
  }

  @override
  Future<SignageEventItem> saveEvent(SignageEventItem item) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) throw StateError('Tenant Signage belum tersedia.');
    final rows = await _supabase
        .from('sg_event_lists')
        .upsert(item.toUpsertMap(tenantId: tenantId))
        .select()
        .limit(1);
    return rows.isEmpty ? item : SignageEventItem.fromMap(rows.first);
  }

  @override
  Future<SignageDevicePairing> createDevicePairing({String? deviceName}) async {
    final response = await _supabase.rpc(
      'create_signage_device_pairing',
      params: {'p_device_name': deviceName, 'p_platform': 'android-tv'},
    );
    if (response is! List || response.isEmpty) {
      throw StateError('Gagal membuat kode pairing device.');
    }
    return SignageDevicePairing.fromMap(
      Map<String, dynamic>.from(response.first as Map),
    );
  }

  @override
  Future<SignageDevicePairing> regenerateDevicePairing(String deviceId) async {
    final response = await _supabase.rpc(
      'regenerate_signage_device_pairing',
      params: {'p_device_id': deviceId},
    );
    if (response is! List || response.isEmpty) {
      throw StateError('Gagal membuat ulang kode pairing device.');
    }
    return SignageDevicePairing.fromMap(
      Map<String, dynamic>.from(response.first as Map),
    );
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
