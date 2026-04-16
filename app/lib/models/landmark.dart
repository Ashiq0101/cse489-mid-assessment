class Landmark {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String imagePath;
  final int isActive;
  final int visitCount;
  final double avgDistance;
  final double score;

  Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.imagePath,
    required this.isActive,
    required this.visitCount,
    required this.avgDistance,
    required this.score,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      lat: json['lat'] is double ? json['lat'] : double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: json['lon'] is double ? json['lon'] : double.tryParse(json['lon'].toString()) ?? 0.0,
      imagePath: json['image'] ?? '',
      isActive: json['is_active'] is int ? json['is_active'] : int.tryParse(json['is_active'].toString()) ?? 1,
      visitCount: json['visit_count'] is int ? json['visit_count'] : int.tryParse(json['visit_count'].toString()) ?? 0,
      avgDistance: json['avg_distance'] is double ? json['avg_distance'] : double.tryParse(json['avg_distance'].toString()) ?? 0.0,
      score: json['score'] is double ? json['score'] : double.tryParse(json['score'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': imagePath,
      'is_active': isActive,
      'visit_count': visitCount,
      'avg_distance': avgDistance,
      'score': score,
    };
  }
}
