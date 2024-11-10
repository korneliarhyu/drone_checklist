import 'package:drone_flight_checklist/view/checklist_form_view.dart'; // Ensure the path is correct
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Flight Checklist', // Optional: Add title for better structure
      theme: ThemeData(
        primarySwatch: Colors.blue, // Optional: Customize app theme
      ),
      home: ChecklistFormView(), // Displays your ChecklistFormView widget
    );
  }
}
