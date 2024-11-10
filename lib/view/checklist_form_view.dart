import 'package:flutter/material.dart';

class ChecklistFormView extends StatefulWidget {
  @override
  _BottomSheetExampleState createState() => _BottomSheetExampleState();
}

class _BottomSheetExampleState extends State<ChecklistFormView> {
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is a Bottom Sheet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('You can add any content here.'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bottom Sheet Example')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet, // Correctly calls the function without arguments
        child: Icon(Icons.add),
      ),
      body: Center(
        child: Text('Press the + button to show the bottom sheet.'),
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  home: ChecklistFormView(),
));
