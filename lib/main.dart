import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'utils/theme.dart';
import 'services/firestore_service.dart';
import 'services/biometric_service.dart';
import 'services/pi_api_service.dart';
import 'services/local_storage_service.dart';
import 'services/sync_service.dart';
import 'services/timetable_service.dart';

import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/session_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/sync_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/student_home.dart';
import 'screens/teacher_home.dart';
import 'screens/common/sync_status_screen.dart';
import 'screens/teacher/realtime_attendance_screen.dart';
import 'screens/teacher/edit_attendance_screen.dart';
import 'screens/auth/teacher_name_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local storage (Hive)
  final localStorageService = LocalStorageService();
  await localStorageService.init();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surfaceDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(AttendanceApp(localStorageService: localStorageService));
}

class AttendanceApp extends StatelessWidget {
  final LocalStorageService localStorageService;

  const AttendanceApp({super.key, required this.localStorageService});

  @override
  Widget build(BuildContext context) {
    // Create shared service instances
    final piApiService = PiApiService();
    piApiService.setBaseUrl(localStorageService.getPiBaseUrl());

    final firestoreService = FirestoreService();
    final biometricService = BiometricService();
    final syncService = SyncService(localStorageService, firestoreService);
    final timetableService = TimetableService();

    return MultiProvider(
      providers: [
        // Services (as values, not ChangeNotifiers)
        Provider<LocalStorageService>.value(value: localStorageService),
        Provider<PiApiService>.value(value: piApiService),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<BiometricService>.value(value: biometricService),

        // Auth Provider
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // Connectivity Provider
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(piApiService),
        ),

        // Attendance Provider
        ChangeNotifierProvider<AttendanceProvider>(
          create: (_) => AttendanceProvider(
            localStorageService,
            piApiService,
            biometricService,
            timetableService,
          ),
        ),

        // Session Provider
        ChangeNotifierProvider<SessionProvider>(
          create: (_) => SessionProvider(firestoreService, piApiService),
        ),

        // Sync Provider (depends on ConnectivityProvider)
        ChangeNotifierProxyProvider<ConnectivityProvider, SyncProvider>(
          create: (ctx) => SyncProvider(
            syncService,
            Provider.of<ConnectivityProvider>(ctx, listen: false),
          ),
          update: (_, connectivity, previous) =>
              previous ?? SyncProvider(syncService, connectivity),
        ),
      ],
      child: MaterialApp(
        title: 'AttendEase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/signup': (ctx) => const SignupScreen(),
          '/forgot_password': (ctx) => const ForgotPasswordScreen(),
          '/student_home': (ctx) => const StudentHome(),
          '/teacher_home': (ctx) => const TeacherHome(),
          '/teacher_name_setup': (ctx) => const TeacherNameSetupScreen(),
          '/sync_status': (ctx) => const SyncStatusScreen(),
          '/realtime_attendance': (ctx) => const RealtimeAttendanceScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/edit_attendance') {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (ctx) => EditAttendanceScreen(
                classId: args['classId']!,
                date: args['date']!,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
