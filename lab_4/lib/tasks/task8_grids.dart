import 'package:flutter/material.dart';

class Task8Screen extends StatelessWidget {
  const Task8Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.amber,
      Colors.cyan, Colors.indigo, Colors.lime, Colors.brown,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Task 8: Grid Displays')),
      body: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        padding: const EdgeInsets.all(8),
        children: List.generate(colors.length, (index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _FullScreenPreview(
                    color: colors[index],
                    index: index,
                  ),
                ),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                color: colors[index].withOpacity(0.7),
                child: Center(
                  child: Text(
                    'Image ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FullScreenPreview extends StatelessWidget {
  final Color color;
  final int index;

  const _FullScreenPreview({required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image ${index + 1}')),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: color.withOpacity(0.7),
          child: Center(
            child: Text(
              'Image ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
