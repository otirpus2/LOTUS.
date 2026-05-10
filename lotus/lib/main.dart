import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_page.dart';
import 'screens/home.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ovpvbuzbazhciqacjptt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92cHZidXpiYXpoY2lxYWNqcHR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzOTc2MDgsImV4cCI6MjA5Mzk3MzYwOH0.jhf_a7r2FhwvJLnIgwACOxLMziHXWazj2iSxgXLZyXs',
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final prefs =
  await SharedPreferences.getInstance();

  bool isLoggedIn =
      prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MyApp(
      isLoggedIn: isLoggedIn,
    ),
  );
}

class MyApp extends StatelessWidget {

  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      home: isLoggedIn
          ? const HomePage()
          : const LoginPage(),
    );
  }
}