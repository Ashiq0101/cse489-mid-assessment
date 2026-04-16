import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../providers/landmark_provider.dart';
import '../models/landmark.dart';
import '../models/visit_history.dart';
import '../models/visit_queue.dart';
import '../db/database_helper.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _center = const LatLng(23.6850, 90.3563); // Center of Bangladesh

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LandmarkProvider>(context, listen: false).fetchLandmarks();
    });
  }

  Color _getMarkerColor(double score) {
    if (score < 30) return Colors.red;
    if (score < 60) return Colors.orange;
    if (score < 80) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Landmarks Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<LandmarkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage.isNotEmpty) {
            return Center(child: Text('Error: \${provider.errorMessage}'));
          }

          List<Marker> markers = provider.landmarks.map((l) {
            return Marker(
              point: LatLng(l.lat, l.lon),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  _showLandmarkDetails(context, l);
                },
                child: Icon(
                  Icons.location_on,
                  color: _getMarkerColor(l.score),
                  size: 40,
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 6.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }

  void _showLandmarkDetails(BuildContext context, Landmark l) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (l.imagePath.isNotEmpty) 
                 Image.network('https://labs.anontech.info/cse489/exm3/\${l.imagePath}', height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 100)),
              const SizedBox(height: 8),
              Text('Score: \${l.score.toStringAsFixed(1)}'),
              Text('Visits: \${l.visitCount}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _visitLandmark(context, l),
                  child: const Text('Visit Landmark'),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _visitLandmark(BuildContext context, Landmark l) async {
    Navigator.pop(context); // close sheet
    try {
      Position position = await Geolocator.getCurrentPosition();
      
      final Distance distanceObj = const Distance();
      final double distanceInMeters = distanceObj.as(LengthUnit.Meter, LatLng(position.latitude, position.longitude), LatLng(l.lat, l.lon));
      
      final provider = Provider.of<LandmarkProvider>(context, listen: false);
      
      final visit = VisitHistory(
        landmarkId: l.id,
        landmarkTitle: l.title,
        visitTime: DateTime.now().toIso8601String(),
        visitorLat: position.latitude,
        visitorLon: position.longitude,
        distance: distanceInMeters,
      );
      await DatabaseHelper.instance.insertVisit(visit);

      if (await provider.hasInternet()) {
        bool success = await ApiService().visitLandmark(l.id, position.latitude, position.longitude);
        if (success) {
           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Landmark visited and synced!')));
           provider.fetchLandmarks(); 
        }
      } else {
        final queueItem = VisitQueue(
          action: 'visit_landmark',
          payload: json.encode({
            'landmark_id': l.id,
            'user_lat': position.latitude,
            'user_lon': position.longitude,
          }),
          timestamp: DateTime.now().toIso8601String(),
        );
        await DatabaseHelper.instance.queueAction(queueItem);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline: Visit queued for sync!')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
    }
  }
}
