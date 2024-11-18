import 'dart:convert';
import 'package:drone_flight_checklist/model/template_question.dart';

class ApiService {
  final String apiUrl = "http://yourapi.com/receive_questions"; // Replace with your actual API endpoint

  // Function to send data to the server (implementation unchanged)
  Future<void> sendQuestions(Questions data) async {
    // Implementation to send data to a server goes here (not shown)
  }

  // Function to use mock data instead of a real API call for testing
  Future<Questions> getQuestions() async {
    // Mock response data (as if it was received from a server)
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

    // Convert the mock response to a Map<String, Question>
    Map<String, Question> questionsMap = {};
    mockResponse.forEach((key, value) {
      questionsMap[key] = Question.fromJson(value);
      // print(questionsMap[key]?.question);
    });

    return Questions(questions: questionsMap); // Return a Questions instance with Map<String, Question>
  }
}
