// ignore_for_file: unused_element
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class AdbManagerPage extends StatefulWidget {
  const AdbManagerPage({super.key});

  @override
  State<AdbManagerPage> createState() => _AdbManagerPageState();
}

class _AdbManagerPageState extends State<AdbManagerPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _apkPathController = TextEditingController(
    text: kIsWeb
        ? ''
        : p.join(
            p.dirname(Platform.resolvedExecutable),
            'apk',
            'app-release.apk',
          ),
  );
  final TextEditingController _launcherPackageController =
      TextEditingController(text: 'com.google.android.apps.tv.launcherx');
  final TextEditingController _customCommandController =
      TextEditingController();
  final TextEditingController _deviceOwnerController = TextEditingController(
    text: 'com.costik.iptv/.MyDeviceAdminReceiver',
  );
  final TextEditingController _userIdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _consoleOutput = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _ipController.dispose();
    _apkPathController.dispose();
    _launcherPackageController.dispose();
    _customCommandController.dispose();
    _deviceOwnerController.dispose();
    _userIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getAdbPath() async {
    if (kIsWeb) return '';
    final executablePath = Platform.resolvedExecutable;
    final executableDir = p.dirname(executablePath);
    final adbPath = p.join(executableDir, 'adb', 'adb.exe');
    return adbPath;
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _consoleOutput += '$message\n';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<bool> _runAdbCommand(List<String> args, {bool silent = false}) async {
    if (kIsWeb) {
      if (!silent) _log('ADB Manager tidak dapat berjalan di lingkungan Web.');
      return false;
    }
    if (mounted) setState(() => _isLoading = true);

    try {
      final adbPath = await _getAdbPath();
      if (!silent) _log('> adb ${args.join(' ')}');

      if (!await File(adbPath).exists()) {
        if (!silent) _log('Error: adb.exe not found at $adbPath');
        if (mounted) setState(() => _isLoading = false);
        return false;
      }

      final result = await Process.run(adbPath, args);

      if (!silent) {
        if (result.stdout.toString().isNotEmpty) {
          _log(result.stdout.toString().trim());
        }
        if (result.stderr.toString().isNotEmpty) {
          _log('Error: ${result.stderr.toString().trim()}');
        }
      }
      return result.exitCode == 0;
    } catch (e) {
      if (!silent) _log('Exception: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  Future<void> _connectToDevice() async {
    if (_ipController.text.isEmpty) {
      _log('Masukkan alamat IP perangkat.');
      return;
    }
    await _runAdbCommand(['connect', _ipController.text]);
  }

  Future<void> _disconnectAll() async {
    await _runAdbCommand(['disconnect']);
  }

  Future<void> _checkDevices() async {
    await _runAdbCommand(['devices']);
  }

  // ---------------------------------------------------------------------------
  // Install
  // ---------------------------------------------------------------------------

  Future<void> _pickApk() async {
    if (kIsWeb) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );

    if (result.isNotEmpty && mounted) {
      setState(() => _apkPathController.text = result.single.path!);
    }
  }

  Future<void> _installApk() async {
    if (_apkPathController.text.isEmpty) {
      _log('Pilih file APK terlebih dahulu.');
      return;
    }
    _log('Menginstall APK... harap tunggu.');
    await _runAdbCommand(['install', '-r', _apkPathController.text]);
  }

  Future<void> _uninstallIptvApp() async {
    const packageName = 'com.costik.iptv';
    _log('Menghapus IPTV app ($packageName)...');
    final success = await _runAdbCommand(['uninstall', packageName]);
    if (success) {
      _log('Berhasil: IPTV app telah dihapus.');
    } else {
      _log('Gagal: Tidak dapat menghapus IPTV app.');
    }
  }

  // ---------------------------------------------------------------------------
  // Launcher
  // ---------------------------------------------------------------------------

  Future<void> _findLaunchers() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final adbPath = await _getAdbPath();
      _log('> adb shell pm list packages');
      if (!await File(adbPath).exists()) {
        _log('Error: adb.exe not found at $adbPath');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final result = await Process.run(adbPath, [
        'shell',
        'pm',
        'list',
        'packages',
      ]);
      if (result.stdout.toString().isNotEmpty) {
        final allPackages = result.stdout.toString().split('\n');
        final launcherPackages = allPackages
            .where((line) => line.toLowerCase().contains('launcher'))
            .toList();
        if (launcherPackages.isNotEmpty) {
          _log('Launcher packages ditemukan:');
          for (var pkg in launcherPackages) {
            _log(pkg.trim());
          }
        } else {
          _log('Tidak ditemukan launcher packages.');
        }
      }
      if (result.stderr.toString().isNotEmpty) {
        _log('Error: ${result.stderr.toString().trim()}');
      }
    } catch (e) {
      _log('Exception: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _disableLauncher({bool silent = false}) async {
    if (_launcherPackageController.text.isEmpty) {
      if (!silent) _log('Masukkan nama package launcher.');
      return false;
    }
    return await _runAdbCommand([
      'shell',
      'pm',
      'disable-user',
      '--user',
      '0',
      _launcherPackageController.text,
    ], silent: silent);
  }

  Future<bool> _enableLauncher({bool silent = false}) async {
    if (_launcherPackageController.text.isEmpty) {
      if (!silent) _log('Masukkan nama package launcher.');
      return false;
    }
    return await _runAdbCommand([
      'shell',
      'pm',
      'enable',
      _launcherPackageController.text,
    ], silent: silent);
  }

  Future<bool> _disableSetupWraith({bool silent = false}) async {
    return await _runAdbCommand([
      'shell',
      'pm',
      'disable-user',
      '--user',
      '0',
      'com.google.android.tungsten.setupwraith',
    ], silent: silent);
  }

  Future<bool> _enableSetupWraith({bool silent = false}) async {
    return await _runAdbCommand([
      'shell',
      'pm',
      'enable',
      'com.google.android.tungsten.setupwraith',
    ], silent: silent);
  }

  Future<bool> _setHomeActivity({bool silent = false}) async {
    return await _runAdbCommand([
      'shell',
      'cmd',
      'package',
      'set-home-activity',
      'com.costik.iptv/.MainActivity',
    ], silent: silent);
  }

  Future<void> _enableIptvLauncher() async {
    _log('Mengaktifkan IPTV Launcher...');
    bool r1 = await _setHomeActivity(silent: true);
    await Future.delayed(const Duration(milliseconds: 500));
    bool r2 = await _disableLauncher(silent: true);
    await Future.delayed(const Duration(milliseconds: 500));
    bool r3 = await _disableSetupWraith(silent: true);
    if (r1 && r2 && r3) {
      _log('Berhasil: IPTV Launcher diaktifkan.');
    } else {
      _log('Gagal: Tidak dapat mengaktifkan IPTV Launcher sepenuhnya.');
    }
  }

  Future<void> _disableIptvLauncher() async {
    _log('Menonaktifkan IPTV Launcher...');
    bool r1 = await _enableLauncher(silent: true);
    await Future.delayed(const Duration(milliseconds: 500));
    bool r2 = await _enableSetupWraith(silent: true);
    if (r1 && r2) {
      _log('Berhasil: IPTV Launcher dinonaktifkan.');
    } else {
      _log('Gagal: Tidak dapat menonaktifkan IPTV Launcher.');
    }
  }

  // ---------------------------------------------------------------------------
  // Device Owner (DCO)
  // ---------------------------------------------------------------------------

  Future<void> _checkAccounts() async {
    _log('Mengecek akun, harap tunggu...');
    await _runAdbCommand([
      'shell',
      'dumpsys account | grep "Account {"',
    ], silent: false);
  }

  Future<void> _clearGsfCache() async {
    _log('Membersihkan GSF Cache...');
    await _runAdbCommand([
      'shell',
      'pm',
      'clear',
      'com.google.android.gsf',
    ], silent: false);
  }

  Future<void> _setDeviceOwner() async {
    if (_deviceOwnerController.text.isEmpty) {
      _log('Masukkan nama komponen device owner.');
      return;
    }
    _log('Mengatur DCO, harap tunggu...');
    await _runAdbCommand([
      'shell',
      'dpm',
      'set-device-owner',
      _deviceOwnerController.text,
    ], silent: false);
  }

  Future<void> _checkDeviceOwner() async {
    _log('Verifikasi DCO, harap tunggu...');
    await _runAdbCommand([
      'shell',
      'dumpsys device_policy | grep -i "Device Owner"',
    ], silent: false);
  }

  Future<void> _removeDeviceOwner() async {
    if (_deviceOwnerController.text.isEmpty) {
      _log('Masukkan nama komponen device owner.');
      return;
    }
    _log('Menghapus DCO, harap tunggu...');
    await _runAdbCommand([
      'shell',
      'dpm',
      'remove-active-admin',
      _deviceOwnerController.text,
    ], silent: false);
  }

  Future<void> _listOwners() async {
    _log('Listing owners...');
    await _runAdbCommand(['shell', 'dpm', 'list-owners'], silent: false);
  }

  // ---------------------------------------------------------------------------
  // User Management
  // ---------------------------------------------------------------------------

  Future<void> _listUsers() async {
    _log('Listing users...');
    await _runAdbCommand(['shell', 'pm', 'list', 'users']);
  }

  Future<void> _removeUser() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _log('Masukkan User ID yang ingin dihapus.');
      return;
    }
    _log('Menghapus user $userId...');
    await _runAdbCommand(['shell', 'pm', 'remove-user', userId]);
  }

  // ---------------------------------------------------------------------------
  // Custom Command
  // ---------------------------------------------------------------------------

  Future<void> _runCustomCommand() async {
    final commandStr = _customCommandController.text.trim();
    if (commandStr.isEmpty) {
      _log('Masukkan perintah custom.');
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      final adbPath = await _getAdbPath();
      String fullCommand = commandStr;
      if (!fullCommand.toLowerCase().startsWith('adb')) {
        fullCommand = 'adb $fullCommand';
      }
      _log('> $fullCommand');
      if (!await File(adbPath).exists()) {
        _log('Error: adb.exe not found at $adbPath');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final escapedAdbPath = "'$adbPath'";
      final psCommand = fullCommand.replaceFirst(
        RegExp(r'^adb\b', caseSensitive: false),
        '& $escapedAdbPath',
      );
      final result = await Process.run('powershell', ['-Command', psCommand]);
      if (result.stdout.toString().isNotEmpty) {
        _log(result.stdout.toString().trim());
      }
      if (result.stderr.toString().isNotEmpty) {
        _log('Error: ${result.stderr.toString().trim()}');
      }
    } catch (e) {
      _log('Exception: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fitur Tidak Tersedia di Versi Web',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ADB Manager memerlukan akses proses sistem lokal (adb.exe) yang hanya dapat dijalankan pada aplikasi Windows Desktop.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL: Controls (Grid)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.adb_rounded,
                        size: 28,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ADB Manager',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola koneksi Android TV dan install aplikasi melalui ADB.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // 1) Device Connection
                      _CompactCard(
                        icon: Icons.wifi_rounded,
                        title: 'Device Connection',
                        width: 320,
                        child: Column(
                          children: [
                            TextField(
                              controller: _ipController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'IP Address (192.168.1.8:5555)',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _connectToDevice,
                                    child: const Text(
                                      'Connect',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _disconnectAll,
                                    child: const Text(
                                      'Disconnect',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _checkDevices,
                                child: const Text(
                                  'List Devices',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2) Install Application
                      _CompactCard(
                        icon: Icons.install_mobile_rounded,
                        title: 'Install Application',
                        width: 320,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _apkPathController,
                                    readOnly: true,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText: 'Pilih file APK',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  onPressed: _isLoading ? null : _pickApk,
                                  icon: const Icon(
                                    Icons.folder_open_rounded,
                                    size: 18,
                                  ),
                                  tooltip: 'Browse',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _installApk,
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Install APK',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : _uninstallIptvApp,
                                child: const Text(
                                  'Uninstall IPTV App',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3) IPTV Launcher Setup
                      _CompactCard(
                        icon: Icons.tv_rounded,
                        title: 'IPTV Launcher Setup',
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _enableIptvLauncher,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Enable IPTV Launcher',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _disableIptvLauncher,
                              child: const Text(
                                'Disable IPTV Launcher',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _findLaunchers,
                              child: const Text(
                                'Find Launchers',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4) User Management
                      _CompactCard(
                        icon: Icons.people_rounded,
                        title: 'User Management',
                        width: 320,
                        child: Column(
                          children: [
                            TextField(
                              controller: _userIdController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'User ID (misal 10)',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _listUsers,
                                    child: const Text(
                                      'List Users',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                    ),
                                    onPressed: _isLoading ? null : _removeUser,
                                    child: const Text(
                                      'Remove User',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 6) DCO Set (Device Owner)
                      _CompactCard(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Device Owner (DCO)',
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _checkAccounts,
                                    child: const Text(
                                      'Check Accounts',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _clearGsfCache,
                                    child: const Text(
                                      'Clear GSF',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _setDeviceOwner,
                                    child: const Text(
                                      'Set DCO',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _checkDeviceOwner,
                                    child: const Text(
                                      'Verify DCO',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _listOwners,
                                    child: const Text(
                                      'List UserO',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _removeDeviceOwner,
                                    child: const Text(
                                      'Rm DCO',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ), // RIGHT PANEL: Custom Command & Console Output
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom Command Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _customCommandController,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Consolas',
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Ketik perintah custom lalu tekan Enter',
                                hintStyle: TextStyle(fontFamily: 'Roboto'),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _runCustomCommand(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _runCustomCommand,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Run',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Console Output
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Console Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              border: const Border(
                                bottom: BorderSide(color: Colors.white10),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.code_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Terminal Output',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () =>
                                      setState(() => _consoleOutput = ''),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'Clear',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Console Body
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                _consoleOutput.isEmpty
                                    ? '>_ Ready...'
                                    : _consoleOutput,
                                style: TextStyle(
                                  color: _consoleOutput.isEmpty
                                      ? Colors.white38
                                      : const Color(0xFF00FF88),
                                  fontFamily: 'Consolas',
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable compact card for ADB Manager Grid layout.
class _CompactCard extends StatelessWidget {
  const _CompactCard({
    required this.icon,
    required this.title,
    required this.child,
    this.width,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
