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
    ], silent: true);
  }

  Future<void> _clearGsfCache() async {
    _log('Membersihkan GSF Cache...');
    await _runAdbCommand([
      'shell',
      'pm',
      'clear',
      'com.google.android.gsf',
    ], silent: true);
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
    ], silent: true);
  }

  Future<void> _checkDeviceOwner() async {
    _log('Verifikasi DCO, harap tunggu...');
    await _runAdbCommand([
      'shell',
      'dumpsys device_policy | grep -i "Device Owner"',
    ], silent: true);
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
    ], silent: true);
  }

  Future<void> _listOwners() async {
    _log('Listing owners...');
    await _runAdbCommand(['shell', 'dpm', 'list-owners'], silent: true);
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
                      'ADB Manager memerlukan akses proses sistem lokal (adb.exe) '
                      'yang hanya dapat dijalankan pada aplikasi Windows Desktop.',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.adb_rounded, size: 28, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'ADB Manager',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola koneksi Android TV dan install aplikasi melalui ADB.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // 1) Device Connection
            _SectionCard(
              icon: Icons.wifi_rounded,
              title: 'Device Connection',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        hintText: 'Alamat IP (misal 192.168.1.8:5555)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _connectToDevice,
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Connect'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _disconnectAll,
                    child: const Text('Disconnect All'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _checkDevices,
                    child: const Text('List Devices'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2) Install Application
            _SectionCard(
              icon: Icons.install_mobile_rounded,
              title: 'Install Application',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apkPathController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Pilih file APK',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _pickApk,
                    child: const Text('Browse...'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _installApk,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Install APK'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    onPressed: _isLoading ? null : _uninstallIptvApp,
                    child: const Text('Uninstall IPTV'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3) IPTV Launcher Setup
            _SectionCard(
              icon: Icons.tv_rounded,
              title: 'IPTV Launcher Setup',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _enableIptvLauncher,
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Enable IPTV Launcher'),
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _disableIptvLauncher,
                    child: const Text('Disable IPTV Launcher'),
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _findLaunchers,
                    child: const Text('Find Launchers'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4) DCO Set
            _SectionCard(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Device Control Owner (DCO)',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : _checkAccounts,
                    child: const Text('Check Accounts'),
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _clearGsfCache,
                    child: const Text('Clear GSF Cache'),
                  ),
                  FilledButton(
                    onPressed: _isLoading ? null : _setDeviceOwner,
                    child: const Text('Set DCO'),
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _checkDeviceOwner,
                    child: const Text('Verify DCO'),
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _listOwners,
                    child: const Text('List UserO'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    onPressed: _isLoading ? null : _removeDeviceOwner,
                    child: const Text('Remove DCO'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5) User Management
            _SectionCard(
              icon: Icons.people_rounded,
              title: 'User Management',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        hintText: 'User ID (misal 10)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _listUsers,
                    child: const Text('List Users'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    onPressed: _isLoading ? null : _removeUser,
                    child: const Text('Remove User'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6) Custom Command
            _SectionCard(
              icon: Icons.terminal_rounded,
              title: 'Custom Command',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCommandController,
                      decoration: const InputDecoration(
                        hintText: 'Perintah ADB (misal shell pm list packages)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _runCustomCommand(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _runCustomCommand,
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Run'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7) Console Output
            _SectionCard(
              icon: Icons.code_rounded,
              title: 'Console Output',
              trailing: TextButton.icon(
                onPressed: () => setState(() => _consoleOutput = ''),
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Clear'),
              ),
              child: Container(
                height: 300,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    _consoleOutput.isEmpty
                        ? '// Output akan muncul di sini...'
                        : _consoleOutput,
                    style: TextStyle(
                      color: _consoleOutput.isEmpty
                          ? Colors.grey
                          : const Color(0xFF00FF88),
                      fontFamily: 'Consolas',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable card section widget for ADB Manager.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing!],
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
