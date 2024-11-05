import 'package:flutter/material.dart';

import '../model/checklist_form_model.dart';

class ChecklistFormView extends StatelessWidget {
  final int formId;
  final Map<String, dynamic> checklist;

  const ChecklistFormView({
    super.key,
    required this.formId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder();
  }
}
