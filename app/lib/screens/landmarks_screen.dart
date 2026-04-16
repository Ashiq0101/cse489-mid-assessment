import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/landmark_provider.dart';

class LandmarksScreen extends StatelessWidget {
  const LandmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landmarks List'),
        actions: [
          Consumer<LandmarkProvider>(
            builder: (context, provider, child) => IconButton(
              icon: Icon(provider.sortByScoreHighToLow ? Icons.arrow_downward : Icons.arrow_upward),
              onPressed: () {
                provider.setSortOrder(!provider.sortByScoreHighToLow);
              },
            ),
          ),
          Consumer<LandmarkProvider>(
             builder: (context, provider, child) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog(context, provider);
              },
            ),
          ),
        ],
      ),
      body: Consumer<LandmarkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage.isNotEmpty) {
            return Center(child: Text('Error: \${provider.errorMessage}'));
          }
          if (provider.landmarks.isEmpty) {
            return const Center(child: Text('No landmarks found.'));
          }

          return ListView.builder(
            itemCount: provider.landmarks.length,
            itemBuilder: (context, index) {
              final l = provider.landmarks[index];
              return ListTile(
                leading: l.imagePath.isNotEmpty 
                  ? Image.network('https://labs.anontech.info/cse489/exm3/\${l.imagePath}', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
                  : const Icon(Icons.image_not_supported),
                title: Text(l.title),
                subtitle: Text('Score: \${l.score.toStringAsFixed(1)} | Visits: \${l.visitCount}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Show details
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context, LandmarkProvider provider) {
    double tempVal = provider.minScoreFilter;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter by Minimum Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Score: \${tempVal.toStringAsFixed(0)}'),
              Slider(
                value: tempVal,
                min: 0,
                max: 100,
                divisions: 10,
                onChanged: (val) {
                  setState(() => tempVal = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.setMinScoreFilter(tempVal);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
