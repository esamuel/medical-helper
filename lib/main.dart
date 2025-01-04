import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/auth_service.dart';
import 'services/medication_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<MedicationService>(
          create: (_) => MedicationService(),
        ),
        Provider<NotificationService>.value(
          value: notificationService,
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => MaterialApp(
          title: 'Medical Helper',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    
    if (user != null) {
      return const HomeScreen();
    }
    
    return const LoginScreen();
  }
}
