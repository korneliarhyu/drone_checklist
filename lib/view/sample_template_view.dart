import 'package:flutter/material.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/database/seed/sample_templates.dart';

class SampleTemplateView extends StatefulWidget {
  const SampleTemplateView({super.key});

  @override
  State<SampleTemplateView> createState() => _SampleTemplateViewState();
}

class _SampleTemplateViewState extends State<SampleTemplateView> {
  bool _isAdded = false;

  @override
  void initState() {
    super.initState();
    _checkTemplate();
  }

  Future<void> _checkTemplate() async {
    final templates = await DatabaseHelper.getAllTemplates();

    final exists = templates.any(
          (template) => template['serverTemplateId'] == 900001,
    );

    setState(() {
      _isAdded = exists;
    });
  }

  Future<void> _addTemplate() async {
    if (_isAdded) return;

    await SampleTemplates.addDroneFlightChecklist();

    setState(() {
      _isAdded = true;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template added successfully'),
      ),
    );
  }

  // STYLING
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Templates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.flight,
                  size: 36,
                  color: Colors.blue,
                ),

                const SizedBox(width: 16),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Drone Flight Checklist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Pre-flight, post-flight, and flight assessment checklist.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                ElevatedButton(
                  onPressed: _isAdded ? null : _addTemplate,
                  child: Text(
                    _isAdded ? 'Added' : 'Add',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}