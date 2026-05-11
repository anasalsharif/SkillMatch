//new api all fixed i used api.env

// app_lifecycle_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:skillmatch_platform/services/socket_service.dart';

final String baseUrl2 = dotenv.env['BASE_URL2']!;

class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  final String? userId;
  final String? token;

  const AppLifecycleManager({
    required this.child,
    this.userId,
    this.token,
    super.key,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  late final SocketService _socketService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePresence();
  }

  Future<void> _initializePresence() async {
    if (widget.userId == null || widget.token == null) return;

    _socketService = SocketService();
    //192.168.1.7
    await _socketService.initializePresence(
      //      url: 'http://192.168.1.7:5000',
      url: baseUrl2,
      userId: widget.userId!,
      token: widget.token!,
    );
    _isInitialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _socketService.updatePresence(false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.updatePresence(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _socketService.updatePresence(false);
      _socketService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
