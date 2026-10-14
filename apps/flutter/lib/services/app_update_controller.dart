import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum AppUpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  ready,
  unavailable,
  failed,
}

/// Startup/resume probes read local patch metadata only. Network operations
/// happen only when the user checks for or downloads an update.
class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    ShorebirdUpdater? updater,
    Future<bool> Function()? hasNetwork,
    this.downloadWait = const Duration(minutes: 2),
  }) : _updater = updater ?? ShorebirdUpdater(),
       _hasNetwork = hasNetwork ?? _connected;

  final ShorebirdUpdater _updater;
  final Future<bool> Function() _hasNetwork;
  final Duration downloadWait;
  AppUpdatePhase _phase = AppUpdatePhase.idle;
  String? _failureMessage;
  String? _readyToken;
  Future<bool>? _localRead;
  Timer? _downloadTimer;
  bool _checking = false;
  bool _downloading = false;
  bool _disposed = false;

  AppUpdatePhase get phase => _phase;
  String? get failureMessage => _failureMessage;
  String? get readyToken => _readyToken;

  static Future<bool> _connected() async {
    final connections = await Connectivity().checkConnectivity();
    return connections.any((value) => value != ConnectivityResult.none);
  }

  void _set(AppUpdatePhase phase, {String? message}) {
    if (_disposed) return;
    _phase = phase;
    _failureMessage = message;
    notifyListeners();
  }

  Future<bool> refreshLocal() {
    return _localRead ??= _readLocal().whenComplete(() => _localRead = null);
  }

  Future<bool> _readLocal() async {
    try {
      if (_disposed) return false;
      if (!_updater.isAvailable) {
        _set(AppUpdatePhase.unavailable);
        return true;
      }
      final patches = await Future.wait([
        _updater.readCurrentPatch(),
        _updater.readNextPatch(),
      ]).timeout(const Duration(seconds: 2));
      if (_disposed) return false;
      final current = patches[0]?.number ?? 0;
      final next = patches[1]?.number ?? 0;
      if (current != next) {
        // Includes a rollback to patch zero. Never claim an update is ready
        // just because update() returned: the automatic updater may be busy.
        _readyToken = '$current:$next';
        _downloadTimer?.cancel();
        _set(AppUpdatePhase.ready);
      } else {
        _readyToken = null;
        if (_phase == AppUpdatePhase.ready) _set(AppUpdatePhase.idle);
      }
      return true;
    } catch (_) {
      // A local diagnostic failure must not interrupt the app or offline use.
      return false;
    }
  }

  Future<void> checkForUpdates() async {
    if (_disposed || _checking || _downloading) return;
    _checking = true;
    _set(AppUpdatePhase.checking);
    try {
      await refreshLocal();
      if (_disposed ||
          _phase == AppUpdatePhase.ready ||
          _phase == AppUpdatePhase.unavailable) {
        return;
      }
      final connected = await _hasNetwork().timeout(const Duration(seconds: 3));
      if (!connected) {
        _set(
          AppUpdatePhase.failed,
          message: "You're offline. Connect to the internet and try again.",
        );
        return;
      }
      final status = await _updater.checkForUpdate().timeout(
        const Duration(seconds: 15),
      );
      await refreshLocal();
      if (_disposed || _phase == AppUpdatePhase.ready) return;
      switch (status) {
        case UpdateStatus.upToDate:
          _set(AppUpdatePhase.upToDate);
        case UpdateStatus.outdated:
          _set(AppUpdatePhase.available);
        case UpdateStatus.unavailable:
          _set(AppUpdatePhase.unavailable);
        case UpdateStatus.restartRequired:
          // Shorebird has independently confirmed that a restart is needed.
          _readyToken ??= 'restart-required';
          _set(AppUpdatePhase.ready);
      }
    } catch (_) {
      if (_phase != AppUpdatePhase.ready) {
        _set(
          AppUpdatePhase.failed,
          message:
              "We couldn't check for updates. Keep reading and try again later.",
        );
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> download() async {
    if (_disposed ||
        _checking ||
        _downloading ||
        _phase != AppUpdatePhase.available) {
      return;
    }
    _downloading = true;
    _set(AppUpdatePhase.downloading);
    try {
      await _updater.update().timeout(downloadWait);
      await refreshLocal();
      if (_disposed || _phase == AppUpdatePhase.ready) return;
      // update() may return immediately when the engine is already downloading.
      // Local probes will announce readiness when the file is actually saved.
      _downloadTimer?.cancel();
      _downloadTimer = Timer(downloadWait, () {
        if (_phase == AppUpdatePhase.downloading) {
          _set(
            AppUpdatePhase.failed,
            message:
                "The update isn't ready yet. Keep reading and try again later.",
          );
        }
      });
    } catch (_) {
      await refreshLocal();
      if (_phase != AppUpdatePhase.ready) {
        _set(
          AppUpdatePhase.failed,
          message:
              "The update isn't ready yet. Keep reading and try again later.",
        );
      }
    } finally {
      _downloading = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _downloadTimer?.cancel();
    super.dispose();
  }
}
