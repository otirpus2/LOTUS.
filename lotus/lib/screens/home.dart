import 'package:flutter/material.dart';
import 'package:lotus/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Home"),
      ),

      body: Center(

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            const Text(
              "Welcome to LOTUS",

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            IconButton(

              onPressed: () async {

                final prefs =
                await SharedPreferences.getInstance();

                await prefs.setBool(
                  'isLoggedIn',
                  false,
                );

                Navigator.pushReplacement(
                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                    const LoginPage(),
                  ),
                );
              },

              icon: const Icon(
                Icons.logout,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}