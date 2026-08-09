import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/main_layout.dart';

void main() {
  runApp(const JustTenukiApp());
}

class JustTenukiApp extends StatelessWidget {
  const JustTenukiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Tenuki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.lexendTextTheme(), // Lexend Font globally
      ),
      home: const MainLayout(),
    );
  }
}
