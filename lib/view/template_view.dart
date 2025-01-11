import 'dart:convert';
import 'package:drone_checklist/view/template_select.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:drone_checklist/model/json_model.dart';
import 'package:drone_checklist/services/api_service.dart';

class TemplateView extends StatelessWidget {
  const TemplateView({super.key});

  // pakai API
  Future<List<Template>> _getAllTemplate() async {
    try {
      final dio = Dio();
      final client = ApiService(dio);

      String responseData = await client.getAllTemplate();

      if (responseData.isNotEmpty) {
        var jsonData = jsonDecode(responseData);
        List<Template> templates =
            List.from(jsonData.map((model) => Template.fromJson(model)));
        return templates;
      } else {
        throw Exception("No data received from the server");
      }
    } on DioException catch (dioError){
      String errorMessage = _handleDioError(dioError);
      print("Error fetching templates: $errorMessage");
      throw Exception(errorMessage);
    } catch (e, s) {
      print("Error fetching templates: $e");
      print("stacktrace: $s");
      throw Exception("An unexpected error occured");
    }
  }

  String _handleDioError(DioException error){
    switch (error.type){
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return "Connection timed out. Please check your internet connection.";
      case DioExceptionType.badResponse:
        return "Server error: ${error.response?.statusCode}. Please try again later.";
      case DioExceptionType.cancel:
        return "Request was cancelled.";
      case DioExceptionType.unknown:
        return "No connection available. Please check your network.";
      default:
        return "An unexpected error occured.";
    }
  }

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'List Template';
    return Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        //Menggunakan API gunakan List<Template>
        body: FutureBuilder<List<Template>>(
          future: _getAllTemplate(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text("No templates available."));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var template = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.all(15),
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),

                      title: Text(template.templateName,
                          style: const TextStyle(fontSize: 20)),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TemplateSelect(
                                      templateId: template.id,
                                    )));
                        // Handle navigation or further actions
                      },
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text("No data available"));
            }
          },
        ),
    );
  }
}
