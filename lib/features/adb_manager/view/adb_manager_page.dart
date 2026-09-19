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

  Future<void> _confirmEnableIptvLauncher() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Konfirmasi Pengaturan Launcher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Mengaktifkan fitur ini akan menjadikan aplikasi IPTV sebagai Launcher Utama (Default) di Android TV.\n\n'
            'Jika setelah proses ini fungsi navigasi atau remote control (seperti tombol Home) tidak merespons dengan normal, Anda dapat mengembalikannya ke pengaturan pabrik dengan menekan tombol "Disable IPTV Launcher".\n\n'
            'Apakah Anda yakin ingin melanjutkan eksekusi?',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _enableIptvLauncher();
    }
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
    // Kita jalankan dumpsys murni, lalu saring (grep) hasilnya di Dart
    // supaya aman berjalan di berbagai OS maupun versi Android.
    final adbPath = await _getAdbPath();
    final result = await Process.run(adbPath, ['shell', 'dumpsys', 'account']);

    if (result.stdout.toString().isNotEmpty) {
      final lines = result.stdout.toString().split('\n');
      final accountLines = lines.where((l) => l.contains('Account {')).toList();

      if (accountLines.isNotEmpty) {
        _log('Ditemukan ${accountLines.length} akun:');
        for (var line in accountLines) {
          _log(line.trim());
        }
      } else {
        _log('Tidak ada akun yang tersimpan di perangkat.');
      }
    } else {
      _log('Gagal membaca data akun atau perangkat tidak merespon.');
    }
  }

  Future<void> _clearGsfCache() async {
    _log('Membersihkan GSF Cache...');
    final adbPath = await _getAdbPath();
    final result = await Process.run(adbPath, [
      'shell',
      'pm',
      'clear',
      'com.google.android.gsf',
    ]);

    if (result.stdout.toString().contains('Success')) {
      _log('GSF Cache Success : Berhasil dibersihkan.');
    } else {
      _log('Selesai memproses pembersihan cache.');
    }
  }

  Future<void> _setDeviceOwner() async {
    if (_deviceOwnerController.text.isEmpty) {
      _log('Masukkan nama komponen device owner.');
      return;
    }
    _log('Mengatur DCO, harap tunggu...');
    final adbPath = await _getAdbPath();
    final result = await Process.run(adbPath, [
      'shell',
      'dpm',
      'set-device-owner',
      _deviceOwnerController.text,
    ]);

    final stdoutStr = result.stdout.toString();
    final stderrStr = result.stderr.toString();

    if (stdoutStr.toLowerCase().contains('success') ||
        stderrStr.toLowerCase().contains('success')) {
      _log('DCO Success : Berhasil dipasang.');
    } else if (stdoutStr.contains('already set') ||
        stderrStr.contains('already set')) {
      _log(
        'Error : DCO sudah terpasang. Harap Remove DCO lama terlebih dahulu.',
      );
    } else if (stdoutStr.contains('Not allowed to set the device owner') ||
        stderrStr.contains('Not allowed to set the device owner')) {
      _log(
        'Error : Gagal memasang DCO. Pastikan tidak ada Akun (Check Accounts) yang tersisa di TV.',
      );
    } else {
      _log('Gagal memasang DCO. Pastikan koneksi perangkat stabil.');
    }
  }

  Future<void> _checkDeviceOwner() async {
    _log('Verifikasi DCO, harap tunggu...');
    final adbPath = await _getAdbPath();
    final result = await Process.run(adbPath, [
      'shell',
      'dumpsys',
      'device_policy',
    ]);

    if (result.stdout.toString().isNotEmpty) {
      final lines = result.stdout.toString().split('\n');
      bool found = false;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().contains('device owner:')) {
          found = true;
          String pkgName = 'com.costik.iptv'; // fallback
          for (int j = i; j < i + 4 && j < lines.length; j++) {
            if (lines[j].trim().startsWith('package=')) {
              pkgName = lines[j].trim().replaceFirst('package=', '');
            }
          }
          _log('DCO Success : $pkgName');
          break;
        }
      }

      if (!found) {
        _log('Status : Tidak ada Device Owner (DCO) yang aktif.');
      }
    } else {
      _log('Gagal memverifikasi DCO atau perangkat tidak merespon.');
    }
  }

  Future<void> _removeDeviceOwner() async {
    if (_deviceOwnerController.text.isEmpty) {
      _log('Masukkan nama komponen device owner.');
      return;
    }
    _log('Menghapus DCO, harap tunggu...');
    final adbPath = await _getAdbPath();
    final result = await Process.run(adbPath, [
      'shell',
      'dpm',
      'remove-active-admin',
      _deviceOwnerController.text,
    ]);

    final stdoutStr = result.stdout.toString();
    final stderrStr = result.stderr.toString();

    if (stdoutStr.toLowerCase().contains('success') ||
        stderrStr.toLowerCase().contains('success')) {
      _log('DCO Success : Berhasil dihapus.');
    } else if (stdoutStr.contains('SecurityException') ||
        stderrStr.contains('SecurityException')) {
      _log(
        'Error : DCO tidak ditemukan atau Anda tidak memiliki akses untuk menghapusnya.',
      );
    } else {
      _log('Selesai memproses penghapusan DCO.');
    }
  }

  Future<void> _listOwners() async {
    _log('Mencari data Owner (UserO)...');
    final adbPath = await _getAdbPath();
    final result = await Process.run(adbPath, ['shell', 'dpm', 'list-owners']);

    if (result.stdout.toString().isNotEmpty) {
      final lines = result.stdout.toString().split('\n');
      bool found = false;
      for (var line in lines) {
        if (line.toLowerCase().contains('admin=')) {
          found = true;
          final comp = line
              .trim()
              .replaceAll('admin=ComponentInfo{', '')
              .replaceAll('}', '');
          final pkg = comp.split('/').first;
          _log('UserO Ditemukan : $pkg');
        }
      }
      if (!found) {
        _log('Status : Tidak ada UserO yang aktif.');
      }
    } else {
      _log('Gagal membaca data Owner.');
    }
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL: Controls (Table-like Rows)
          Expanded(
            flex: 6,
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
                    'Kelola koneksi Android TV dan eksekusi perintah secara aman.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Table-like Container
                  Container(
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
                    child: Column(
                      children: [
                        // 1) Device Connection
                        _ActionRow(
                          icon: Icons.wifi_rounded,
                          title: 'Connection',
                          children: [
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _ipController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: '192.168.1.8:5555',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: _isLoading ? null : _connectToDevice,
                              icon: const Icon(Icons.link_rounded, size: 16),
                              label: const Text(
                                'Connect',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _disconnectAll,
                              child: const Text(
                                'Disconnect All',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _checkDevices,
                              child: const Text(
                                'List Devices',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),

                        // 2) Install Application
                        _ActionRow(
                          icon: Icons.install_mobile_rounded,
                          title: 'Application',
                          children: [
                            SizedBox(
                              width: 200,
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
                            const SizedBox(width: 10),
                            IconButton.outlined(
                              onPressed: _isLoading ? null : _pickApk,
                              icon: const Icon(
                                Icons.folder_open_rounded,
                                size: 18,
                              ),
                              tooltip: 'Browse',
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
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
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                              ),
                              onPressed: _isLoading ? null : _uninstallIptvApp,
                              child: const Text(
                                'Uninstall IPTV App',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),

                        // 3) IPTV Launcher Setup
                        _ActionRow(
                          icon: Icons.tv_rounded,
                          title: 'Launcher',
                          children: [
                            FilledButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _confirmEnableIptvLauncher,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Enable IPTV Launcher',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _disableIptvLauncher,
                              child: const Text(
                                'Disable IPTV Launcher',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _findLaunchers,
                              child: const Text(
                                'Find Launchers',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),

                        // 4) DCO Set (Device Owner)
                        _ActionRow(
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'DCO Control',
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 20,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Untuk menggunakan fungsi ini, rekomendasi terbaik adalah menggunakan sambungan USB dari komputer/laptop ke TV atau STB. Pastikan Anda sudah menonton tutorial penggunaan DCO sebelum mengeksekusi fitur ini.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade900,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _checkAccounts,
                              child: const Text(
                                'Check Accounts',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _clearGsfCache,
                              child: const Text(
                                'Clear GSF',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _isLoading ? null : _setDeviceOwner,
                              child: const Text(
                                'Set DCO',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _checkDeviceOwner,
                              child: const Text(
                                'Verify DCO',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _listOwners,
                              child: const Text(
                                'List UserO',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                              ),
                              onPressed: _isLoading ? null : _removeDeviceOwner,
                              child: const Text(
                                'Rm DCO',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),

                        // 5) User Management
                        _ActionRow(
                          icon: Icons.people_rounded,
                          title: 'Users',
                          children: [
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _userIdController,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'User ID (10)',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _isLoading ? null : _listUsers,
                              child: const Text(
                                'List Users',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                              ),
                              onPressed: _isLoading ? null : _removeUser,
                              child: const Text(
                                'Remove User',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT PANEL: Custom Command & Console Output
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
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
                                hintText: 'Ketik perintah custom (misal: shell pm list) lalu tekan Enter',
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

/// Reusable Action Row for ADB Manager Table Layout.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Label
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right: Actions (Wrapped so it doesn't overflow on small screens)
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
