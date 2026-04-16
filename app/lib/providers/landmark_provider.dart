import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/landmark.dart';
import '../models/visit_history.dart';
import '../models/visit_queue.dart';
import '../services/api_service.dart';
import '../db/database_helper.dart';

class LandmarkProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Landmark> _landmarks = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  bool _sortByScoreHighToLow = false;
  double _minScoreFilter = 0.0;

  List<Landmark> get landmarks {
    List<Landmark> filtered = _landmarks.where((l) => l.score >= _minScoreFilter).toList();
    if (_sortByScoreHighToLow) {
      filtered.sort((a, b) => b.score.compareTo(a.score));
    } else {
      filtered.sort((a, b) => a.score.compareTo(b.score));
    }
    return filtered;
  }
  
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get sortByScoreHighToLow => _sortByScoreHighToLow;
  double get minScoreFilter => _minScoreFilter;

  Future<bool> hasInternet() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> fetchLandmarks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (await hasInternet()) {
        await syncPendingQueue(); // Sync any offline actions first
        _landmarks = await _apiService.getLandmarks();
        await _dbHelper.cacheLandmarks(_landmarks); // Cache new data
      } else {
        _landmarks = await _dbHelper.getCachedLandmarks(); // Fallback to offline
        if (_landmarks.isEmpty) {
          _errorMessage = 'No internet connection and no cached data.';
        } else {
          _errorMessage = 'Offline mode: Showing cached data';
        }
      }
    } catch (e) {
      _landmarks = await _dbHelper.getCachedLandmarks();
      if (_landmarks.isEmpty) {
         _errorMessage = e.toString();
      } else {
         _errorMessage = 'Offline mode: Showing cached data';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncPendingQueue() async {
    List<VisitQueue> pending = await _dbHelper.getPendingQueue();
    for (var task in pending) {
      try {
        if (task.action == 'visit_landmark') {
           final payload = json.decode(task.payload);
           bool success = await _apiService.visitLandmark(
             payload['landmark_id'], 
             payload['user_lat'], 
             payload['user_lon']
           );
           if (success) await _dbHelper.deleteQueueItem(task.id!);
        } else if (task.action == 'create_landmark') {
           final payload = json.decode(task.payload);
           bool success = await _apiService.createLandmark(
             payload['title'], 
             payload['lat'], 
             payload['lon'], 
             task.imagePath ?? ''
           );
           if (success) await _dbHelper.deleteQueueItem(task.id!);
        }
      } catch (e) {
        // Leave in queue
      }
    }
  }

  void setSortOrder(bool highToLow) {
    _sortByScoreHighToLow = highToLow;
    notifyListeners();
  }

  void setMinScoreFilter(double score) {
    _minScoreFilter = score;
    notifyListeners();
  }
}

