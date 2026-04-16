import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../providers/landmark_provider.dart';
import '../models/visit_queue.dart';
import '../db/database_helper.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  String _title = '';
  double? _lat;
  double? _lon;
  String _imagePath = '';
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied')));
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _lat = position.latitude;
      _lon = position.longitude;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fetch location first.')));
      return;
    }

    _formKey.currentState!.save();
    
    setState(() { _isSubmitting = true; });

    try {
      final provider = Provider.of<LandmarkProvider>(context, listen: false);
      if (await provider.hasInternet()) {
         bool success = await _apiService.createLandmark(_title, _lat!, _lon!, _imagePath);
         if (mounted) {
           if (success) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Landmark created successfully!')));
             _formKey.currentState!.reset();
             setState(() { _lat = null; _lon = null; _imagePath = ''; });
             provider.fetchLandmarks(); // Refresh map
           } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create landmark.')));
           }
         }
      } else {
         final queueItem = VisitQueue(
           action: 'create_landmark',
           payload: json.encode({
             'title': _title,
             'lat': _lat,
             'lon': _lon,
           }),
           imagePath: _imagePath,
           timestamp: DateTime.now().toIso8601String(),
         );
         await DatabaseHelper.instance.queueAction(queueItem);
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline: Create queued for sync!')));
           _formKey.currentState!.reset();
           setState(() { _lat = null; _lon = null; _imagePath = ''; });
         }
      }
    } catch (e) {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Landmark')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_lat != null && _lon != null 
                        ? 'Lat: \${_lat!.toStringAsFixed(4)}, Lon: \${_lon!.toStringAsFixed(4)}' 
                        : 'Location not fetched'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Get Location'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_imagePath.isNotEmpty ? 'Image Selected' : 'No Image Selected'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('SUBMIT LANDMARK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
