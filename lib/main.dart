import 'package:flutter/material.dart';
import 'package:drone_checklist/view/checklist_form_view.dart';
import 'package:drone_checklist/model/template_question.dart';
import 'package:drone_checklist/database/database_helper.dart';

void main() {
  // final database = new DatabaseHelper();
  // database.insertDummyTemplate();
  //
  // var question1;
  // database.getRandomTemplate().then((question) {
  //   question1 = Questions.toString(question);
  //   print(question1); // Handle `question1` here
  // });
  // final question = database.getRandomTemplate();
  //
  //final question1 = Questions.toString(question as Map<String, dynamic>);
  Questions sampleQuestions = Questions.toString({
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
        "required": true
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
