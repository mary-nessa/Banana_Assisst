import 'package:flutter/material.dart';

class PesticidesScreen extends StatelessWidget {
  const PesticidesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesticides & Pest Control'),
        backgroundColor: Colors.green[800],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Here you can display a list of common pesticides, '
                'application instructions, safety guidelines, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
