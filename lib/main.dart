import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drone_checklist/view/form_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _buildLightTheme(),
      home: FormCreate(),
    );
  }

  ThemeData _buildLightTheme() {
    var baseTheme = ThemeData.light();
    return baseTheme.copyWith(
      textTheme: GoogleFonts.latoTextTheme(baseTheme.textTheme),
    );
  }
}
