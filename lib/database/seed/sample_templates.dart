import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/model/template_model.dart';

class SampleTemplates {
  static final Map<String, dynamic> droneFlightChecklist = {
    'assessment': {
      '1': {
        'question': 'Pilot Name',
        'type': 'text',
        'option': [],
        'required': true,
      },
      '2': {
        'question': 'Flight Purpose',
        'type': 'text',
        'option': [],
        'required': true,
      },
    },

    'pre': {
      '1': {
        'question': 'Weather Condition',
        'type': 'dropdown',
        'option': [
          'Clear',
          'Cloudy',
          'Light Rain',
          'Unsafe',
        ],
        'required': true,
      },
      '2': {
        'question': 'Equipment Check',
        'type': 'checklist',
        'option': [
          'Battery',
          'Propeller',
          'Camera',
          'GPS',
        ],
        'required': true,
      },
      '3': {
        'question': 'Drone Condition',
        'type': 'multiple',
        'option': [
          'Good',
          'Needs Inspection',
          'Not Ready',
        ],
        'required': true,
      },
    },

    'post': {
      '1': {
        'question': 'Flight Notes',
        'type': 'longtext',
        'option': [],
        'required': false,
      },
      '2': {
        'question': 'Post-Flight Condition',
        'type': 'multiple',
        'option': [
          'Good',
          'Minor Issue',
          'Needs Maintenance',
        ],
        'required': true,
      },
    },
  };

  static Future<void> addDroneFlightChecklist() async {
    final template = TemplateModel(
      templateId: null,
      serverTemplateId: 900001,
      templateName: 'Drone Flight Checklist',
      formType: 'assessment-pre-post',
      updatedDate: DateTime.now(),
      templateFormData: droneFlightChecklist,
      deletedAt: null,
    );

    await DatabaseHelper.insertTemplate(template);
  }
}