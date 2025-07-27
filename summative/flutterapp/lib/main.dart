import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CropYieldApp());
}

class CropYieldApp extends StatelessWidget {
  const CropYieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropYield',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
