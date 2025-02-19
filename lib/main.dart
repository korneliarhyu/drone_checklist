import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drone_checklist/view/form_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _buildLightTheme(),
      home: const FormView(),
    );
  }

  ThemeData _buildLightTheme() {
    var baseTheme = ThemeData.light();
    return baseTheme.copyWith(
      textTheme: GoogleFonts.latoTextTheme(baseTheme.textTheme),
    );
  }
}
