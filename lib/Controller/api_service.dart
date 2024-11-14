import 'dart:convert';
import 'package:drone_flight_checklist/model/template_question.dart';

class ApiService {
  final String apiUrl = "http://yourapi.com/receive_questions"; // replace with your endpoint if using a real API

  // Function to send data to the server (same as before)
  Future<void> sendQuestions(Questions data) async {
    // Implementation for sending data to a server (unchanged)
  }

  // Function to use mock data instead of a real API call for testing
  Future<Questions> getQuestions() async {
    // Mock response data (as if it was received from a server)
    final Map<String, dynamic> mockResponse = {
      "question1": {
        "question": "Multiple Example",
        "type": "multiple",
        "option": [
          "multiple1",
          "multiple2",
          "multiple3"
        ],
        "required": true
      },
      "question2": {
        "question": "Checklist Example",
        "type": "checklist",
        "option": [
          "checklist1",
          "checklist2",
          "checklist3"
        ],
        "required": false
      },
      "question3": {
        "question": "Dropdown Example",
        "type": "dropdown",
        "option": [
          "dropdown1",
          "dropdown2",
          "dropdown3"
        ],
        "required": true
      },
      "question4": {
        "question": "test text",
        "type": "text",
        "option": [],
        "required": true
      }
    };

    // Simulating JSON decoding as if it came from an API response
    final jsonData = jsonEncode(mockResponse); // Convert to JSON string for consistency
    final Map<String, dynamic> decodedData = jsonDecode(jsonData); // Decode it back to a map
    return Questions.fromJson(decodedData); // Assuming Questions.fromJson exists
  }
}
