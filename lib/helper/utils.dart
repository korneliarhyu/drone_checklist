import 'package:flutter/material.dart';

enum AlertType { success, failed }

Future<void> showAlert(
    BuildContext context,
    String title,
    String message,
    AlertType type,
    VoidCallback onOkPressed) {
  Color bgColor = Colors.lightGreen;
  if (type == AlertType.failed) {
    bgColor = Colors.redAccent;
  } else if (type == AlertType.success) {
    bgColor = Colors.greenAccent;
  }

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor: bgColor,
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOkPressed();
              },
              child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
