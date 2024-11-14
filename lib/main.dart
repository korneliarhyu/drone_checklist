import 'package:drone_flight_checklist/Database/database_helper.dart';
import 'package:drone_flight_checklist/view/checklist_form_view.dart';
import 'package:flutter/material.dart';
import 'package:drone_flight_checklist/model/template_question.dart'; // Import your Questions model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await DatabaseHelper.addTemplateExample(); // Uncomment if needed
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample Questions instance to pass
    Questions sampleQuestions = Questions(
      questions: {
        "question1": Question(
          question: "Sample Question Text",
          type: "text",
          option: [],
          required: true,
        ),
        "question2": Question(
          question: "Multiple Choice Example",
          type: "multiple",
          option: ["Option 1", "Option 2", "Option 3"],
          required: false,
        ),
      },
    );

    return MaterialApp(
      title: 'Drone Flight Checklist',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Customize app theme
      ),
      home: ChecklistFormView(templateQuestions: sampleQuestions), // Pass the Questions object
    );
  }
}
