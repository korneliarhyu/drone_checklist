import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:drone_flight_checklist/Database/database_helper.dart'; // Adjust the import path based on your project structure
import 'package:drone_flight_checklist/model/checklist_form_model.dart'; // Import model if you need to create objects


class CreateForm extends StatefulWidget {
  @override
  _CreateFormState createState() => _CreateFormState();
}

class _CreateFormState extends State<CreateForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _formNameController = TextEditingController();
  final TextEditingController _templateIDController = TextEditingController();
  final TextEditingController _updatedByController = TextEditingController();
  final TextEditingController _formDataController = TextEditingController();

  // Example function to save form (you can customize it)
  void _saveForm() async {
  if (_formKey.currentState?.validate() ?? false) {
    final int? templateId = int.tryParse(_templateIDController.text);
    if (templateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Template ID'))
      );
      return;
    }

    final String formName = _formNameController.text;
    final String updatedBy = _updatedByController.text;

    // Assuming formData is a JSON string that needs to be converted to a Map
    Map<String, dynamic> checklistFormData;
    try {
      checklistFormData = jsonDecode(_formDataController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid form data format'))
      );
      return;
    }

    final formModel = ChecklistFormModel(
      templateId: templateId,
      formName: formName,
      updatedBy: updatedBy,
      updatedDate: DateTime.now(), // Assuming this is what you want
      checklistFormData: checklistFormData,
    );

    try {
      await DatabaseHelper.createChecklistForm(formModel);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form Saved!'))
      );
      _formNameController.clear();
      _templateIDController.clear();
      _updatedByController.clear();
      _formDataController.clear();
      Navigator.pop(context, formName); // Return the form name
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving form: $e'))
      );
    }
  }
}

  
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _formNameController,
                decoration: InputDecoration(labelText: 'Form Name'),
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter a form name';
                //   }
                //   return null;
                // },
              ),
              TextFormField(
                controller: _templateIDController,
                decoration: InputDecoration(labelText: 'Template ID'),
                keyboardType: TextInputType.number,
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter a template ID';
                //   }
                //   if (int.tryParse(value) == null) {
                //     return 'Please enter a valid number';
                //   }
                //   return null;
                // },
              ),
              TextFormField(
                controller: _updatedByController,
                decoration: InputDecoration(labelText: 'Updated By'),
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter the name of the updater';
                //   }
                //   return null;
                // },
              ),
              TextFormField(
                controller: _formDataController,
                decoration: InputDecoration(labelText: 'Form Data'),
                maxLines: 5,
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter form data';
                //   }
                //   return null;
                // },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveForm,
                child: Text('Save Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
