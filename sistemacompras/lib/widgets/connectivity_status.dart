import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class ConnectivityStatus extends StatefulWidget {
  @override
  State<ConnectivityStatus> createState() => _ConnectivityStatusState();
}

class _ConnectivityStatusState extends State<ConnectivityStatus> {
  bool _isOnline = true;
  late final Connectivity _connectivity;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivity.onConnectivityChanged.listen((result) async {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        try {
          final syncService = SyncService(ApiService());
          await syncService.syncPending();
        } catch (_) {}
      }
    });
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isOnline ? Icons.cloud_done : Icons.cloud_off, color: Colors.white),
          SizedBox(width: 8),
          Text(_isOnline ? 'Modo Online' : 'Modo Offline', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
