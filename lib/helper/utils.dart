import 'package:flutter/material.dart';

enum AlertType { success, failed }

void showAlert(
    BuildContext context, String title, String message, AlertType type) {
  Color bgColor = Colors.lightGreen;
  if (type == AlertType.failed) {
    bgColor = Colors.redAccent;
  } else if (type == AlertType.success) {
    bgColor = Colors.greenAccent;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor: bgColor,
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(), child: Text("OK")),
        ],
      );
    },
  );
}
