import 'dart:typed_data';

import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:costikstudio/features/signage/view/signage_content_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('media section shows edit and delete actions for saved media', (
    tester,
  ) async {
    final cubit = await _pumpMediaSection(tester);
    addTearDown(cubit.close);

    expect(find.text('Lobby Video'), findsOneWidget);
    expect(find.byTooltip('Edit media'), findsOneWidget);
    expect(find.byTooltip('Hapus media'), findsOneWidget);
  });

  testWidgets('add media dialog is image-only and offers upload action', (
    tester,
  ) async {
    final cubit = await _pumpMediaSection(tester);
    addTearDown(cubit.close);

    await tester.tap(find.text('Tambah Media'));
    await tester.pumpAndSettle();

    expect(find.text('Upload Gambar'), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    expect(find.text('Video'), findsNothing);
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('media section renders as usable cards on phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = await _pumpMediaSection(tester);
    addTearDown(cubit.close);

    expect(find.text('Media'), findsWidgets);
    expect(find.text('Path / URL'), findsOneWidget);
    expect(find.text('Aksi'), findsOneWidget);
    expect(find.byTooltip('Edit media'), findsOneWidget);
    expect(find.byTooltip('Hapus media'), findsOneWidget);
  });
}

Future<SignageAdminCubit> _pumpMediaSection(WidgetTester tester) async {
  final repository = _FakeSignageAdminRepository(
    mediaItems: const [
      SignageMediaItem(
        id: 'media-1',
        fileName: 'Lobby Video',
        storagePath: 'https://example.com/lobby.mp4',
        publicUrl: 'https://example.com/lobby.mp4',
        mediaType: 'video',
      ),
    ],
  );
  final cubit = SignageAdminCubit(repository: repository);

  await cubit.load();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: const SingleChildScrollView(child: SignageMediaSection()),
        ),
      ),
    ),
  );

  return cubit;
}

class _FakeSignageAdminRepository extends SignageAdminRepository {
  _FakeSignageAdminRepository({this.mediaItems = const []});

  List<SignageMediaItem> mediaItems;

  @override
  Future<String?> currentTenantId() async => 'tenant-1';

  @override
  Future<SignageHotelProfile?> fetchHotelProfile() async => null;

  @override
  Future<SignageHotelProfile> saveHotelProfile(
    SignageHotelProfile profile,
  ) async => profile;

  @override
  Future<String> uploadHotelLogo({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async => 'https://example.com/$fileName';

  @override
  Future<String> uploadMediaImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async => 'https://example.com/media/$fileName';

  @override
  Future<List<SignageDevice>> fetchDevices() async => const [];

  @override
  Future<SignageDeviceQuota> fetchDeviceQuota() async =>
      const SignageDeviceQuota(deviceLimit: 0, usedDevices: 0);

  @override
  Future<List<SignageMediaItem>> fetchMedia() async => mediaItems;

  @override
  Future<SignageMediaItem> saveMedia(SignageMediaItem item) async {
    final saved = item.id == null
        ? SignageMediaItem(
            id: 'media-${mediaItems.length + 1}',
            fileName: item.fileName,
            storagePath: item.storagePath,
            mediaType: item.mediaType,
            publicUrl: item.publicUrl,
          )
        : item;
    mediaItems = [
      for (final media in mediaItems)
        if (media.id != saved.id) media,
      saved,
    ];
    return saved;
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    mediaItems = [
      for (final media in mediaItems)
        if (media.id != mediaId) media,
    ];
  }

  @override
  Future<List<SignagePlaylistItem>> fetchPlaylists() async => const [];

  @override
  Future<SignagePlaylistItem> savePlaylist(SignagePlaylistItem item) async =>
      item;

  @override
  Future<void> deletePlaylist(String playlistId) async {}

  @override
  Future<List<SignagePlaylistVideoItem>> fetchPlaylistItems(
    String playlistId,
  ) async => const [];

  @override
  Future<Map<String, int>> fetchPlaylistVideoCounts() async => const {};

  @override
  Future<void> replacePlaylistItems(
    String playlistId,
    List<String> mediaIds,
  ) async {}

  @override
  Future<List<SignageEventItem>> fetchEvents() async => const [];

  @override
  Future<SignageEventItem> saveEvent(SignageEventItem item) async => item;

  @override
  Future<void> deleteEvent(String eventId) async {}

  @override
  Future<SignageDevicePairing> createDevicePairing({
    String? deviceName,
  }) async => SignageDevicePairing(
    deviceId: 'device-1',
    pairingCode: '123456',
    expiresAt: DateTime(2030),
  );

  @override
  Future<SignageDevicePairing> regenerateDevicePairing(String deviceId) async =>
      SignageDevicePairing(
        deviceId: deviceId,
        pairingCode: '654321',
        expiresAt: DateTime(2030),
      );

  @override
  Future<void> updateDeviceSlideDuration(
    String deviceId, {
    required int durationSeconds,
  }) async {}

  @override
  Future<void> updateDeviceAppMode(
    String deviceId, {
    required SignageAppMode appMode,
  }) async {}

  @override
  Future<void> updateDeviceEventTheme(
    String deviceId, {
    required SignageEventTheme eventTheme,
  }) async {}

  @override
  Future<void> updateDeviceEventBackground(
    String deviceId, {
    String? eventBackgroundUrl,
  }) async {}

  @override
  Future<void> deleteDevice(String deviceId) async {}
}
