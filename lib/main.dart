import 'package:flutter/material.dart';
import 'package:media_vault/screens/onboarding_screen.dart';
import 'package:media_vault/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  runApp(MyApp(initialRoute: seenOnboarding ? '/splash' : '/'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Media Vault',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const OnBoarding(),
        '/splash': (context) => const SplashScreen(),
      },
    );
  }
}
