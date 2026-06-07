import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Tambahin import ini

import 'firebase_options.dart';
import 'features/auth/pages/login_page.dart';
import 'features/consultation/config/gemini_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi API key Gemini secara aman
  await GeminiConfig.initialize();

  // 2. Bungkus app lo pake ProviderScope biar Riverpod-nya nyala
  runApp(const ProviderScope(child: GradventureApp())); 
}

class GradventureApp extends StatelessWidget {
  const GradventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Sementara pake MaterialApp biasa gapapa, nanti kita ubah jadi MaterialApp.router
    return const MaterialApp( 
      debugShowCheckedModeBanner: false,
      title: 'Gradventure',
      home: LoginPage(),
    );
  }
}