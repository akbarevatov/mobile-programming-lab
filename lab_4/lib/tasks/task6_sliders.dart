import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Task6Screen extends StatefulWidget {
  const Task6Screen({super.key});

  @override
  State<Task6Screen> createState() => _Task6ScreenState();
}

class _Task6ScreenState extends State<Task6Screen> {
  double _volume = 50;
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task 6: Sliders & Pickers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Volume Control', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_volume.round()}%',
                    onChanged: (val) {
                      setState(() {
                        _volume = val;
                      });
                    },
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
            Text(
              '${_volume.round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Date Picker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Select Date'),
            ),
            const SizedBox(height: 12),
            if (_selectedDate != null)
              Text(
                'Selected: ${DateFormat.yMMMMd().format(_selectedDate!)}',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
