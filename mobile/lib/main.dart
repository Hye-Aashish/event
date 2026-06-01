import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/dio_client.dart';

import 'models/event_model.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/event_detail_screen.dart';
import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/verification_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final authProvider = AuthProvider();
  DioClient.onUnauthorized = () {
    authProvider.logout(remote: false);
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  runApp(NavratriApp(authProvider: authProvider));
}

class NavratriApp extends StatelessWidget {
  final AuthProvider authProvider;
  const NavratriApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'Navratri 2024',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          ErrorWidget.builder = (details) => Scaffold(
                body: Center(
                  child: Text('UI Error: ${details.exception}',
                      style: const TextStyle(color: Colors.red)),
                ),
              );
          return child!;
        },
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/otp': (_) => const OtpScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => HomeScreen(key: homeScreenKey),
          '/tickets': (_) => const TicketsScreen(),
          '/ticket-detail': (_) => const TicketDetailScreen(),
          '/verification': (_) => const VerificationScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/scanner': (_) => const ScannerScreen(),
          '/events': (_) => const EventsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/event-detail') {
            final event = settings.arguments as EventModel;
            return MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            );
          }
          return null;
        },
      ),
    );
  }
}
