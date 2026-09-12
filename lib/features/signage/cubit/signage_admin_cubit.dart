import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageAdminState extends Equatable {
  const SignageAdminState({
    this.isLoading = false,
    this.isSaving = false,
    this.hotelProfile,
    this.devices = const [],
    this.devicePairing,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final SignageHotelProfile? hotelProfile;
  final List<SignageDevice> devices;
  final SignageDevicePairing? devicePairing;
  final String? errorMessage;
  final String? successMessage;

  SignageAdminState copyWith({
    bool? isLoading,
    bool? isSaving,
    SignageHotelProfile? hotelProfile,
    List<SignageDevice>? devices,
    SignageDevicePairing? devicePairing,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return SignageAdminState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hotelProfile: hotelProfile ?? this.hotelProfile,
      devices: devices ?? this.devices,
      devicePairing: devicePairing ?? this.devicePairing,
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
    devicePairing,
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
      emit(
        state.copyWith(
          isLoading: false,
          hotelProfile: hotelProfile ?? const SignageHotelProfile(),
          devices: devices,
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

  Future<void> createDevicePairing({String? deviceName}) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));
    try {
      final pairing = await _repository.createDevicePairing(
        deviceName: deviceName,
      );
      final devices = await _repository.fetchDevices();
      emit(
        state.copyWith(
          isSaving: false,
          devicePairing: pairing,
          devices: devices,
          successMessage: 'Kode pairing device berhasil dibuat.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }
}
