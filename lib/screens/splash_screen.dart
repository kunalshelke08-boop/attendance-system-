import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Minimum splash display time + auth resolution
    Future.delayed(const Duration(seconds: 2), () {
      _tryNavigate();
    });

    // Timeout fallback — go to login if auth doesn't resolve in 4s
    _timeoutTimer = Timer(const Duration(seconds: 4), () {
      if (!_navigated && mounted) {
        _navigated = true;
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  void _tryNavigate() {
    if (_navigated || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // If auth state has been resolved
    if (authProvider.status != AuthStatus.initial) {
      _doNavigate(authProvider);
      return;
    }

    // Auth state still loading — listen for changes
    void listener() {
      if (_navigated || !mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.status != AuthStatus.initial) {
        auth.removeListener(listener);
        _doNavigate(auth);
      }
    }

    authProvider.addListener(listener);
  }

  void _doNavigate(AuthProvider authProvider) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timeoutTimer?.cancel();

    if (authProvider.isAuthenticated) {
      final role = authProvider.user?.role ?? 'student';
      if (role == 'teacher') {
        Navigator.pushReplacementNamed(context, '/teacher_home');
      } else {
        Navigator.pushReplacementNamed(context, '/student_home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AttendEase',
                  style: AppTheme.headingLarge.copyWith(
                    fontSize: 32,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Biometric Attendance System',
                  style: AppTheme.bodyMedium.copyWith(
                    letterSpacing: 2,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentTeal.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
