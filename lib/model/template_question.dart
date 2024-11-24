class Questions {
  Map<String, Question> questions;

  Questions({required this.questions});

  // Convert JSON
  factory Questions.toString(Map<String, dynamic> json) {
    Map<String, Question> questionsMap = {};
    json.forEach((key, value) {
      questionsMap[key] = Question.jsonToString(value);
    });
    return Questions(questions: questionsMap);
  }

  // Convert Questions to JSON
  Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonMap = {};
    questions.forEach((key, question) {
      jsonMap[key] = question.toJson();
    });
    return jsonMap;
  }
}

class Question {
  String question;
  String type;
  List<String> option;
  bool required;

  Question({
    required this.question,
    required this.type,
    required this.option,
    required this.required,
  });

  factory Question.jsonToString(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      type: json['type'],
      option: List<String>.from(json['option']),
      required: json['required'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'type': type,
      'option': option,
      'required': required,
    };
  }
}
