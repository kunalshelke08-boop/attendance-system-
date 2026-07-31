import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/pi_api_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final PiApiService _piApi;

  bool _isOnline = false;
  bool _isPiReachable = false;
  bool _isSessionActive = false;
  StreamSubscription? _subscription;

  bool get isOnline => _isOnline;
  bool get isPiReachable => _isPiReachable;
  bool get isSessionActive => _isSessionActive;

  String get statusText {
    if (_isOnline && _isPiReachable) return 'Online + Pi Connected';
    if (_isOnline) return 'Online';
    if (_isPiReachable) return 'Pi Connected (Offline)';
    return 'Offline';
  }

  ConnectivityProvider(this._piApi) {
    _init();
  }

  Future<void> _init() async {
    // Initial check — v5+ returns List<ConnectivityResult>
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    // Listen for changes — v5+ emits List<ConnectivityResult>
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();
    });

    // Check Pi
    await checkPiConnection();
  }

  Future<void> checkPiConnection() async {
    final status = await _piApi.getServerStatus();
    _isPiReachable = status['status'] == 'ok';
    _isSessionActive = status['session_active'] ?? false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    await checkPiConnection();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
