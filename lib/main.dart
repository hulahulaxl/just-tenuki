import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/main_layout.dart';

void main() {
  runApp(const GoReviewApp());
}

class GoReviewApp extends StatelessWidget {
  const GoReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoReview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.lexendTextTheme(), // Lexend Font globally
      ),
      home: const MainLayout(),
    );
  }
}
