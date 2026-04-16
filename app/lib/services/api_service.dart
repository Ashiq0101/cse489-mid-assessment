import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/landmark.dart';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/exm3/api.php';
  static const String studentKey = '24241376';

  Future<List<Landmark>> getLandmarks() async {
    final response = await http.get(Uri.parse('$baseUrl?action=get_landmarks&key=$studentKey'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Landmark.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load landmarks');
    }
  }

  Future<bool> visitLandmark(int landmarkId, double lat, double lon) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=visit_landmark&key=$studentKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'landmark_id': landmarkId,
        'user_lat': lat,
        'user_lon': lon,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> createLandmark(String title, double lat, double lon, String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl?action=create_landmark&key=$studentKey'));
    request.fields['title'] = title;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    
    // Add image file if a valid path is provided
    if (imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return response.statusCode == 200;
  }

  Future<bool> deleteLandmark(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=delete_landmark&key=$studentKey'),
      body: {'id': id.toString()},
    );

    return response.statusCode == 200;
  }

  Future<bool> restoreLandmark(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl?action=restore_landmark&key=$studentKey'),
      body: {'id': id.toString()},
    );

    return response.statusCode == 200;
  }
}
