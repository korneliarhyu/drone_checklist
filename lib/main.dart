import 'package:flutter/material.dart';
import 'package:drone_checklist/view/form_view.dart';
import 'package:drone_checklist/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const FormView(),
    );
  }
}
