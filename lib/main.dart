import 'package:drone_flight_checklist/Database/database_helper.dart';
import 'package:drone_flight_checklist/view/checklist_form_view.dart';
import 'package:drone_flight_checklist/view/checklist_form_create.dart'; 
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.addTemplateExample();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'Drone Flight Checklist', 
      theme: ThemeData(
        primarySwatch: Colors.blue, //Customize app theme
      ),
      home: ChecklistFormView(), // Displays ChecklistFormView widget
    );
  }
}
