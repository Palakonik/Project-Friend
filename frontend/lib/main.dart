import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/blocked_users_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await Firebase.initializeApp();

  // Supabase initialization
  // TODO: Supabase projenizi oluşturduktan sonra bu bilgileri güncelleyin
  await Supabase.initialize(
    url: 'https://bmcbzkkewskuibojxvud.supabase.co',
    anonKey: 'sb_publishable_Ml7r3_OXOW2Tk_yOwm3TBQ_CUU1MTat',
  );

  runApp(const MyApp());
}

// Global Supabase client (kolay erişim için)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Arkadaşlık Uygulaması',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
          '/search': (context) => const SearchScreen(),
          '/conversations': (context) => const ConversationsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/admin': (context) => const AdminPanelScreen(),
          '/blocked': (context) => const BlockedUsersScreen(),
          '/verify-email': (context) => const EmailVerificationScreen(),
        },
      ),
    );
  }
}

/// Auth Wrapper - Oturum durumuna göre yönlendirme
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Yükleniyor...'),
                ],
              ),
            ),
          );
        }

        if (auth.isLoggedIn) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
