class VisitHistory {
  final int? id; // SQLite auto-increment ID
  final int landmarkId;
  final String landmarkTitle;
  final String visitTime; // ISO-8601 string or similar
  final double visitorLat;
  final double visitorLon;
  final double distance; // Distance between user and landmark when visited

  VisitHistory({
    this.id,
    required this.landmarkId,
    required this.landmarkTitle,
    required this.visitTime,
    required this.visitorLat,
    required this.visitorLon,
    required this.distance,
  });

  factory VisitHistory.fromMap(Map<String, dynamic> map) {
    return VisitHistory(
      id: map['id'],
      landmarkId: map['landmark_id'] is int ? map['landmark_id'] : int.tryParse(map['landmark_id'].toString()) ?? 0,
      landmarkTitle: map['landmark_title'] ?? '',
      visitTime: map['visit_time'] ?? '',
      visitorLat: map['visitor_lat'] is double ? map['visitor_lat'] : double.tryParse(map['visitor_lat'].toString()) ?? 0.0,
      visitorLon: map['visitor_lon'] is double ? map['visitor_lon'] : double.tryParse(map['visitor_lon'].toString()) ?? 0.0,
      distance: map['distance'] is double ? map['distance'] : double.tryParse(map['distance'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'landmark_id': landmarkId,
      'landmark_title': landmarkTitle,
      'visit_time': visitTime,
      'visitor_lat': visitorLat,
      'visitor_lon': visitorLon,
      'distance': distance,
    };
  }
}
