import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';

// Entry point: Flutter starts running the app from here.
void main() {
  runApp(const MyApp());
}

// Root widget: keeps global app settings like theme and initial page.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF59E0B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      // ThemeData applies a consistent style to all screens.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        useMaterial3: true,
        // App-level AppBar theme. The foregroundColor here sets the default
        // color for AppBar icons and text. We use a dark color so icons/text
        // are readable on light backgrounds.
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF0F172A), // dark foreground for app bars
        ),
        // Default text theme: body text uses the same dark foreground color.
        // This keeps text consistent across pages unless overridden locally.
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF0F172A)), // default body text color
        ),
      ),
      // First screen shown when the app opens.
      home: const DashboardPage(),
    );
  }
}
