import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  final api = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..init()),
        ChangeNotifierProvider(create: (_) => BookingProvider(api)),
      ],
      child: const BookMeApp(),
    ),
  );
}

class BookMeApp extends StatelessWidget {
  const BookMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F9D8A)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.initializing) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
