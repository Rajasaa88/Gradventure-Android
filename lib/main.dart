import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'features/auth/pages/login_page.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/consultation/config/gemini_config.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi API key Gemini secara aman
  await GeminiConfig.initialize();

  // Inisialisasi layanan notifikasi lokal
  await NotificationService().init();

  // 2. Bungkus app lo pake ProviderScope biar Riverpod-nya nyala
  runApp(const ProviderScope(child: GradventureApp())); 
}

class GradventureApp extends StatelessWidget {
  const GradventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gradventure',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B5CFA)),
        useMaterial3: true,
        fontFamily: 'Plus Jakarta Sans', // Assuming the font might be added or default sans is used
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return const DashboardPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}