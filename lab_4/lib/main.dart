import 'package:flutter/material.dart';
import 'tasks/task1_selection.dart';
import 'tasks/task2_input.dart';
import 'tasks/task3_buttons.dart';
import 'tasks/task4_indicators.dart';
import 'tasks/task5_dialogs.dart';
import 'tasks/task6_sliders.dart';
import 'tasks/task7_lists.dart';
import 'tasks/task8_grids.dart';
import 'tasks/task9_navigation.dart';
import 'tasks/task10_containers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 4 - Flutter Widgets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = <Map<String, dynamic>>[
      {'title': 'Task 1: Selection Controls', 'screen': const Task1Screen()},
      {'title': 'Task 2: Input Fields', 'screen': const Task2Screen()},
      {'title': 'Task 3: Buttons & Actions', 'screen': const Task3Screen()},
      {'title': 'Task 4: Indicators & Feedback', 'screen': const Task4Screen()},
      {'title': 'Task 5: Dialogs & Modals', 'screen': const Task5Screen()},
      {'title': 'Task 6: Sliders & Pickers', 'screen': const Task6Screen()},
      {'title': 'Task 7: Scrollable Collections', 'screen': const Task7Screen()},
      {'title': 'Task 8: Grid Displays', 'screen': const Task8Screen()},
      {'title': 'Task 9: Navigation Controls', 'screen': const Task9Screen()},
      {'title': 'Task 10: Structural Containers', 'screen': const Task10Screen()},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Lab 4: Flutter Mobile Widgets')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(tasks[index]['title']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => tasks[index]['screen'] as Widget),
              );
            },
          );
        },
      ),
    );
  }
}
