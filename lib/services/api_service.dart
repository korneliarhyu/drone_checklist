import 'dart:convert';
import 'package:drone_checklist/model/template_question.dart';
import 'package:http/http.dart';

class ApiService {
  final String apiUrl = "http://yourapi.com/receive_questions";

  //API Services for getting all templates id from website to application.
  Future<void> getAllTemplate(templateId ) async {

  }


  Future<Questions> getQuestions() async {
    final Map<String, dynamic> mockResponse = {
      "question1": {
        "question": "Multiple Example",
        "type": "multiple",
        "option": ["multiple1", "multiple2", "multiple3"],
        "required": true
      },
      "question2": {
        "question": "Checklist Example",
        "type": "checklist",
        "option": ["checklist1", "checklist2", "checklist3"],
        "required": false
      },
      "question3": {
        "question": "Dropdown Example",
        "type": "dropdown",
        "option": ["dropdown1", "dropdown2", "dropdown3"],
        "required": true
      },
      "question4": {
        "question": "Test Text",
        "type": "text",
        "option": [],
        "required": true
      }
    };


    Map<String, Question> questionsMap = {};
    mockResponse.forEach((key, value) {
      questionsMap[key] = Question.jsonToString(value);
      //test debug template
      // print(questionsMap[key]?.question);
    });

    return Questions(questions: questionsMap);
  }
}
