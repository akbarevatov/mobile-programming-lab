import 'package:flutter/material.dart';

class Task10Screen extends StatelessWidget {
  const Task10Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task 10: Structural Containers')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Information Card',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.person, size: 40, color: Colors.indigo),
                title: const Text('John Doe'),
                subtitle: const Text('Flutter Developer'),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action button tapped')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FAQ Section',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text('What is Flutter?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Flutter is an open-source UI software development kit created by Google. '
                    'It is used to develop cross-platform applications for Android, iOS, Linux, '
                    'macOS, Windows, and the web from a single codebase.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text('What language does Flutter use?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Flutter uses Dart, a programming language also developed by Google. '
                    'Dart is optimized for building UIs and supports both ahead-of-time (AOT) '
                    'and just-in-time (JIT) compilation.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text('Is Flutter free to use?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Yes, Flutter is completely free and open-source. You can use it for '
                    'personal and commercial projects without any licensing fees.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              leading: Icon(Icons.help_outline),
              title: Text('How do I install Flutter?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'You can download the Flutter SDK from flutter.dev and follow the '
                    'installation guide for your operating system. The setup includes '
                    'installing the SDK, setting up an editor, and running flutter doctor '
                    'to verify your environment.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
