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

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final hotelProfile = await _repository.fetchHotelProfile();
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      final mediaItems = await _repository.fetchMedia();
      final playlists = await _repository.fetchPlaylists();
      final events = await _repository.fetchEvents();
      emit(
        state.copyWith(
          isLoading: false,
          hotelProfile: hotelProfile ?? const SignageHotelProfile(),
          devices: devices,
          deviceQuota: deviceQuota,
          mediaItems: mediaItems,
          playlists: playlists,
          events: events,
          clearMessages: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> saveHotelProfile(SignageHotelProfile profile) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final savedProfile = await _repository.saveHotelProfile(profile);
      emit(
        state.copyWith(
          isSaving: false,
          hotelProfile: savedProfile,
          successMessage: 'Profil hotel Signage berhasil disimpan.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> saveMedia(SignageMediaItem item) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.saveMedia(item);
      final mediaItems = await _repository.fetchMedia();
      emit(
        state.copyWith(
          isSaving: false,
          mediaItems: mediaItems,
          successMessage: 'Media berhasil disimpan.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> savePlaylist(SignagePlaylistItem item) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.savePlaylist(item);
      final playlists = await _repository.fetchPlaylists();
      emit(
        state.copyWith(
          isSaving: false,
          playlists: playlists,
          successMessage: 'Playlist berhasil disimpan.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> saveEvent(SignageEventItem item) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.saveEvent(item);
      final events = await _repository.fetchEvents();
      emit(
        state.copyWith(
          isSaving: false,
          events: events,
          successMessage: 'Event berhasil disimpan.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> createDevicePairing({String? deviceName}) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final pairing = await _repository.createDevicePairing(
        deviceName: deviceName,
      );
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      emit(
        state.copyWith(
          isSaving: false,
          devicePairing: pairing,
          devices: devices,
          deviceQuota: deviceQuota,
          successMessage: 'Kode pairing device berhasil dibuat.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      await _repository.deleteDevice(deviceId);
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      emit(
        state.copyWith(
          isSaving: false,
          devices: devices,
          deviceQuota: deviceQuota,
          successMessage: 'Device Signage berhasil dihapus.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> regenerateDevicePairing(String deviceId) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final pairing = await _repository.regenerateDevicePairing(deviceId);
      final devices = await _repository.fetchDevices();
      final deviceQuota = await _repository.fetchDeviceQuota();
      emit(
        state.copyWith(
          isSaving: false,
          devicePairing: pairing,
          devices: devices,
          deviceQuota: deviceQuota,
          successMessage: 'Kode pairing device berhasil dibuat ulang.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }
}
