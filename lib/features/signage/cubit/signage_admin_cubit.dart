import 'dart:typed_data';

import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageAdminState extends Equatable {
  const SignageAdminState({
    this.isLoading = false,
    this.isSaving = false,
    this.hotelProfile,
    this.devices = const [],
    this.mediaItems = const [],
    this.playlists = const [],
    this.playlistVideoCounts = const {},
    this.events = const [],
    this.devicePairing,
    this.deviceQuota = const SignageDeviceQuota(deviceLimit: 0, usedDevices: 0),
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final SignageHotelProfile? hotelProfile;
  final List<SignageDevice> devices;
  final List<SignageMediaItem> mediaItems;
  final List<SignagePlaylistItem> playlists;
  final Map<String, int> playlistVideoCounts;
  final List<SignageEventItem> events;
  final SignageDevicePairing? devicePairing;
  final SignageDeviceQuota deviceQuota;
  final String? errorMessage;
  final String? successMessage;

  SignageAdminState copyWith({
    bool? isLoading,
    bool? isSaving,
    SignageHotelProfile? hotelProfile,
    List<SignageDevice>? devices,
    List<SignageMediaItem>? mediaItems,
    List<SignagePlaylistItem>? playlists,
    Map<String, int>? playlistVideoCounts,
    List<SignageEventItem>? events,
    SignageDevicePairing? devicePairing,
    SignageDeviceQuota? deviceQuota,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return SignageAdminState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hotelProfile: hotelProfile ?? this.hotelProfile,
      devices: devices ?? this.devices,
      mediaItems: mediaItems ?? this.mediaItems,
      playlists: playlists ?? this.playlists,
      playlistVideoCounts: playlistVideoCounts ?? this.playlistVideoCounts,
      events: events ?? this.events,
      devicePairing: devicePairing ?? this.devicePairing,
      deviceQuota: deviceQuota ?? this.deviceQuota,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    hotelProfile,
    devices,
    mediaItems,
    playlists,
    playlistVideoCounts,
    events,
    devicePairing,
    deviceQuota,
    errorMessage,
    successMessage,
  ];
}

class SignageAdminCubit extends Cubit<SignageAdminState> {
  SignageAdminCubit({required this._repository})
    : super(const SignageAdminState());

  final SignageAdminRepository _repository;

  void _safeEmit(SignageAdminState nextState) {
    if (!isClosed) emit(nextState);
  }

  Future<void> load() async {
    _safeEmit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final hotelProfile = await _repository.fetchHotelProfile();
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      final mediaItems = await _repository.fetchMedia();
      final playlists = await _repository.fetchPlaylists();
      final playlistVideoCounts = await _repository.fetchPlaylistVideoCounts();
      final events = await _repository.fetchEvents();
      _safeEmit(
        state.copyWith(
          isLoading: false,
          hotelProfile: hotelProfile ?? const SignageHotelProfile(),
          devices: devices,
          deviceQuota: deviceQuota,
          mediaItems: mediaItems,
          playlists: playlists,
          playlistVideoCounts: playlistVideoCounts,
          events: events,
          clearMessages: true,
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> saveHotelProfile(SignageHotelProfile profile) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final savedProfile = await _repository.saveHotelProfile(profile);
      _safeEmit(
        state.copyWith(
          isSaving: false,
          hotelProfile: savedProfile,
          successMessage: 'Profil hotel Signage berhasil disimpan.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<String?> uploadHotelLogo({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final url = await _repository.uploadHotelLogo(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      _safeEmit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Logo hotel berhasil diupload.',
        ),
      );
      return url;
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      return null;
    }
  }

  Future<void> saveMedia(SignageMediaItem item) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.saveMedia(item);
      final mediaItems = await _repository.fetchMedia();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          mediaItems: mediaItems,
          successMessage: 'Media berhasil disimpan.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> savePlaylist(SignagePlaylistItem item) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.savePlaylist(item);
      final playlists = await _repository.fetchPlaylists();
      final playlistVideoCounts = await _repository.fetchPlaylistVideoCounts();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          playlists: playlists,
          playlistVideoCounts: playlistVideoCounts,
          successMessage: 'Playlist berhasil disimpan.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> savePlaylistWithVideos({
    SignagePlaylistItem? existing,
    required String name,
    required List<String> mediaIds,
    required bool isEnabled,
  }) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final saved = await _repository.savePlaylist(
        SignagePlaylistItem(
          id: existing?.id,
          name: name,
          mediaId: mediaIds.isNotEmpty ? mediaIds.first : existing?.mediaId,
          path: existing?.path,
          isEnabled: isEnabled,
        ),
      );
      if (saved.id != null && saved.id!.isNotEmpty) {
        await _repository.replacePlaylistItems(saved.id!, mediaIds);
      }
      final playlists = await _repository.fetchPlaylists();
      final playlistVideoCounts = await _repository.fetchPlaylistVideoCounts();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          playlists: playlists,
          playlistVideoCounts: playlistVideoCounts,
          successMessage: existing == null
              ? 'Playlist berhasil ditambahkan.'
              : 'Playlist berhasil diubah.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.deletePlaylist(playlistId);
      final playlists = await _repository.fetchPlaylists();
      final playlistVideoCounts = await _repository.fetchPlaylistVideoCounts();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          playlists: playlists,
          playlistVideoCounts: playlistVideoCounts,
          successMessage: 'Playlist berhasil dihapus.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<List<SignagePlaylistVideoItem>> playlistItems(String playlistId) {
    return _repository.fetchPlaylistItems(playlistId);
  }

  Future<void> saveEvent(SignageEventItem item) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.saveEvent(item);
      final events = await _repository.fetchEvents();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          events: events,
          successMessage: 'Event berhasil disimpan.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> createDevicePairing({String? deviceName}) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final pairing = await _repository.createDevicePairing(
        deviceName: deviceName,
      );
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          devicePairing: pairing,
          devices: devices,
          deviceQuota: deviceQuota,
          successMessage: 'Kode pairing device berhasil dibuat.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> updateDeviceSlideDuration(
    String deviceId, {
    required int durationSeconds,
  }) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.updateDeviceSlideDuration(
        deviceId,
        durationSeconds: durationSeconds,
      );
      final devices = await _repository.fetchDevices();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          devices: devices,
          successMessage: 'Durasi slide Daily Event berhasil disimpan.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> updateDeviceAppMode(
    String deviceId, {
    required SignageAppMode appMode,
  }) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.updateDeviceAppMode(deviceId, appMode: appMode);
      final devices = await _repository.fetchDevices();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          devices: devices,
          successMessage: 'Mode aplikasi device berhasil disimpan.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.deleteDevice(deviceId);
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          devices: devices,
          deviceQuota: deviceQuota,
          successMessage: 'Device Signage berhasil dihapus.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> regenerateDevicePairing(String deviceId) async {
    _safeEmit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final pairing = await _repository.regenerateDevicePairing(deviceId);
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      _safeEmit(
        state.copyWith(
          isSaving: false,
          devicePairing: pairing,
          devices: devices,
          deviceQuota: deviceQuota,
          successMessage: 'Kode pairing device berhasil dibuat ulang.',
        ),
      );
    } catch (e) {
      _safeEmit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }
}
