import 'package:flutter/material.dart';

class Task1Screen extends StatefulWidget {
  const Task1Screen({super.key});

  @override
  State<Task1Screen> createState() => _Task1ScreenState();
}

class _Task1ScreenState extends State<Task1Screen> {
  bool darkMode = false;
  bool agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task 1: Selection Controls')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: darkMode,
              onChanged: (val) {
                setState(() {
                  darkMode = val;
                });
              },
            ),
            const Divider(),
            CheckboxListTile(
              title: const Text('Agree to Terms'),
              subtitle: const Text('You must agree before continuing'),
              value: agreeToTerms,
              onChanged: (val) {
                setState(() {
                  agreeToTerms = val ?? false;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: agreeToTerms
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings saved!')),
                      );
                    }
                  : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
