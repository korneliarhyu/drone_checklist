import 'package:flutter/material.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/view/checklist_form_create.dart';
import 'package:drone_checklist/model/template_question.dart';
import 'package:drone_checklist/view/template_list_view.dart';

class TemplateDetail extends StatefulWidget {
  final int templateId;

  const TemplateDetail({
    super.key,
    required this.templateId
  });

  @override
  _TemplateDetailState createState() => _TemplateDetailState();
}

class _TemplateDetailState extends State<TemplateDetail> {
  Map<String, dynamic>? _templateData;

  void _loadTemplateData() async {
    var templateData = await DatabaseHelper.getTemplateById(widget.templateId);
    setState(() {
      _templateData = templateData;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadTemplateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Template Detail"),
      ),
      body: _templateData == null ? const Center(
        child: Text(
          "No Template Available Yet :(",
          style: TextStyle(fontSize: 18),
        ),
      ):
      ListView(
        children: [
          ListTile(
            title: Text(_templateData!['templateName'],
            style: TextStyle(fontSize: 18)),
            subtitle: Text("Template ID: ${_templateData!['templateId']}"),
          ),
          Divider(),
          ListTile(
            title: Text("Form Data:"),
            subtitle: Text(_templateData!['templateFormData']),
          )
        ],
      ),
    );
  }
}