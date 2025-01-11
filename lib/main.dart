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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<NotificationService>.value(value: notificationService),
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ProxyProvider<User?, MedicationService>(
          create: (_) => MedicationService(),
          update: (_, user, previousService) {
            debugPrint('Updating MedicationService with user: ${user?.uid}');
            return MedicationService(userId: user?.uid);
          },
          dispose: (_, service) {
            debugPrint('Disposing MedicationService');
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Medical Helper',
            theme: ThemeData.light().copyWith(
              primaryColor: const Color(0xFF2196F3),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF2196F3),
                error: Colors.red.shade700,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
              navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
                  }
                  return const TextStyle(fontSize: 12);
                }),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: const Color(0xFF1565C0),
              scaffoldBackgroundColor: const Color(0xFF1A1A1A),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF1565C0),
                error: Colors.red.shade300,
                surface: const Color(0xFF1A1A1A),
                onSurface: Colors.white70,
              ),
              navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
                  }
                  return const TextStyle(fontSize: 12);
                }),
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    return user != null ? const HomeScreen() : const LoginScreen();
  }
}
