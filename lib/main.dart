import 'package:flutter/material.dart';
import 'package:crumb/services/auth_layout.dart';
import 'package:crumb/services/notif_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final notifService = NotificationService();
  await notifService.init();
  await notifService.requestPermission();
  await notifService.scheduleProgressiveReminders(); 

  await notifService.scheduleInstant10SecTest();  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B6B4A)),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(const Color(0xFF8B6B4A)),
          side: const BorderSide(color: Color(0xFF8B6B4A)),
        ),
      ),
      home: const AuthLayout(),
    );
  }
}