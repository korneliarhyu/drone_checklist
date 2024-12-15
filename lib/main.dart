import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drone_checklist/view/form_view.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: FormCreate(),
    );
  }
}
