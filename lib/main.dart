import 'package:drone_flight_checklist/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:drone_flight_checklist/view/checklist_form_view.dart';
import 'package:drone_flight_checklist/model/template_question.dart';

void main() {
  // Create a sample templateQuestions instance
  // Question question1 = Question(question: "question1", type: "dropdown", option: ["op1", "op2", "op3"], required: false);
  // Map<String, Question> someMap = {"question1": question1};
  Questions sampleQuestions = Questions.fromJson({
      "question1": {
        "question": "Question no.1",
        "type": "multiple",
        "option": ["multiple1", "multiple2", "multiple3"],
        "required": true
      },
      "question2": {
        "question": "Question no.2",
        "type": "checklist",
        "option": ["checklist1", "checklist2", "checklist3"],
        "required": false
      },
      "question3": {
        "question": "Question no.3",
        "type": "dropdown",
        "option": ["dropdown1", "dropdown2", "dropdown3"],
        "required": true
      },
      "question4": {
        "question": "Question no.4",
        "type": "text",
        "option": [],
        "required": true
      }
    });

  runApp(MaterialApp(
    home: ChecklistFormView(templateQuestions: sampleQuestions),
  ));
}
