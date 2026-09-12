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

enum SignageAppMode {
  dailyEvent('daily_event', 'Daily Event'),
  videoPlayer('video_player', 'Video Player');

  const SignageAppMode(this.value, this.label);

  final String value;
  final String label;

  static SignageAppMode fromValue(String? value) {
    return SignageAppMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => SignageAppMode.dailyEvent,
    );
  }
}

class SignageDevice extends Equatable {
  const SignageDevice({
    required this.id,
    required this.name,
    required this.isVideo,
    required this.isPromo,
    required this.promoDuration,
    required this.tableColumn,
    this.eventSlideDurationSeconds = 7,
    this.appMode = SignageAppMode.dailyEvent,
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
  final int eventSlideDurationSeconds;
  final SignageAppMode appMode;
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
      eventSlideDurationSeconds:
          (map['event_slide_duration_seconds'] as num?)?.round() ?? 7,
      appMode: SignageAppMode.fromValue(map['app_mode'] as String?),
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
    eventSlideDurationSeconds,
    appMode,
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

class SignagePlaylistVideoItem extends Equatable {
  const SignagePlaylistVideoItem({
    this.id,
    required this.playlistId,
    this.mediaId,
    this.sortOrder = 0,
  });

  final String? id;
  final String playlistId;
  final String? mediaId;
  final int sortOrder;

  factory SignagePlaylistVideoItem.fromMap(Map<String, dynamic> map) {
    return SignagePlaylistVideoItem(
      id: map['id'] as String?,
      playlistId: map['playlist_id'] as String? ?? '',
      mediaId: map['media_id'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, playlistId, mediaId, sortOrder];
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

class SignageDeviceQuota extends Equatable {
  const SignageDeviceQuota({
    required this.deviceLimit,
    required this.usedDevices,
  });

  final int deviceLimit;
  final int usedDevices;

  bool get canAddDevice => usedDevices < deviceLimit;

  factory SignageDeviceQuota.fromMap(Map<String, dynamic> map) {
    return SignageDeviceQuota(
      deviceLimit: map['device_limit'] as int? ?? 0,
      usedDevices: map['used_devices'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [deviceLimit, usedDevices];
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
  Future<SignageDeviceQuota> fetchDeviceQuota();
  Future<List<SignageMediaItem>> fetchMedia();
  Future<SignageMediaItem> saveMedia(SignageMediaItem item);
  Future<List<SignagePlaylistItem>> fetchPlaylists();
  Future<SignagePlaylistItem> savePlaylist(SignagePlaylistItem item);
  Future<void> deletePlaylist(String playlistId);
  Future<List<SignagePlaylistVideoItem>> fetchPlaylistItems(String playlistId);
  Future<Map<String, int>> fetchPlaylistVideoCounts();
  Future<void> replacePlaylistItems(String playlistId, List<String> mediaIds);
  Future<List<SignageEventItem>> fetchEvents();
  Future<SignageEventItem> saveEvent(SignageEventItem item);
  Future<SignageDevicePairing> createDevicePairing({String? deviceName});
  Future<SignageDevicePairing> regenerateDevicePairing(String deviceId);
  Future<void> updateDeviceSlideDuration(
    String deviceId, {
    required int durationSeconds,
  });
  Future<void> updateDeviceAppMode(
    String deviceId, {
    required SignageAppMode appMode,
  });
  Future<void> deleteDevice(String deviceId);
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
  Future<SignageDeviceQuota> fetchDeviceQuota() async {
    final response = await _supabase.rpc('get_signage_device_quota');
    if (response is! List || response.isEmpty) {
      return const SignageDeviceQuota(deviceLimit: 0, usedDevices: 0);
    }
    return SignageDeviceQuota.fromMap(
      Map<String, dynamic>.from(response.first as Map),
    );
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
  Future<void> deletePlaylist(String playlistId) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) throw StateError('Tenant Signage belum tersedia.');
    await _supabase
        .from('sg_playlist_items')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('tenant_id', tenantId);
    await _supabase
        .from('sg_playlists')
        .delete()
        .eq('id', playlistId)
        .eq('tenant_id', tenantId);
  }

  @override
  Future<List<SignagePlaylistVideoItem>> fetchPlaylistItems(
    String playlistId,
  ) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) return const [];
    final rows = await _supabase
        .from('sg_playlist_items')
        .select()
        .eq('tenant_id', tenantId)
        .eq('playlist_id', playlistId)
        .order('sort_order')
        .order('created_at');
    return rows.map(SignagePlaylistVideoItem.fromMap).toList();
  }

  @override
  Future<Map<String, int>> fetchPlaylistVideoCounts() async {
    final tenantId = await currentTenantId();
    if (tenantId == null) return const {};
    final rows = await _supabase
        .from('sg_playlist_items')
        .select('playlist_id')
        .eq('tenant_id', tenantId)
        .limit(2000);
    final counts = <String, int>{};
    for (final row in rows) {
      final playlistId = row['playlist_id'] as String?;
      if (playlistId == null || playlistId.isEmpty) continue;
      counts[playlistId] = (counts[playlistId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<void> replacePlaylistItems(
    String playlistId,
    List<String> mediaIds,
  ) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) throw StateError('Tenant Signage belum tersedia.');
    await _supabase
        .from('sg_playlist_items')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('tenant_id', tenantId);
    if (mediaIds.isEmpty) return;
    final rows = [
      for (var i = 0; i < mediaIds.length; i++)
        {
          'tenant_id': tenantId,
          'playlist_id': playlistId,
          'media_id': mediaIds[i],
          'sort_order': i,
        },
    ];
    await _supabase.from('sg_playlist_items').insert(rows);
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
  Future<void> updateDeviceSlideDuration(
    String deviceId, {
    required int durationSeconds,
  }) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) throw StateError('Tenant Signage belum tersedia.');
    await _supabase
        .from('sg_devices')
        .update({
          'event_slide_duration_seconds': durationSeconds.clamp(3, 60),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deviceId)
        .eq('tenant_id', tenantId);
  }

  @override
  Future<void> updateDeviceAppMode(
    String deviceId, {
    required SignageAppMode appMode,
  }) async {
    final tenantId = await currentTenantId();
    if (tenantId == null) throw StateError('Tenant Signage belum tersedia.');
    await _supabase
        .from('sg_devices')
        .update({
          'app_mode': appMode.value,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deviceId)
        .eq('tenant_id', tenantId);
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    await _supabase.rpc(
      'delete_signage_device',
      params: {'p_device_id': deviceId},
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
