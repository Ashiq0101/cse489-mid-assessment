import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/visit_history.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activity'),
      ),
      body: FutureBuilder<List<VisitHistory>>(
        future: DatabaseHelper.instance.getVisitHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No visit history found locally.'));
          }

          final visits = snapshot.data!;
          return ListView.builder(
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final v = visits[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.deepPurple),
                title: Text('Visited: \${v.landmarkTitle}'),
                subtitle: Text('Distance: \${v.distance.toStringAsFixed(2)} meters\nTime: \${v.visitTime}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}

