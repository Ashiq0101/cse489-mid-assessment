class VisitQueue {
  final int? id; // SQLite auto-increment ID
  final String action; // 'visit_landmark' or 'create_landmark'
  final String payload; // JSON representation of the request body or form fields
  final String status; // 'pending' or 'failed'
  final String timestamp; // When the action was generated locally
  final String? imagePath; // If the action is 'create_landmark', we might want to store the local image path

  VisitQueue({
    this.id,
    required this.action,
    required this.payload,
    this.status = 'pending',
    required this.timestamp,
    this.imagePath,
  });

  factory VisitQueue.fromMap(Map<String, dynamic> map) {
    return VisitQueue(
      id: map['id'],
      action: map['action'] ?? '',
      payload: map['payload'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] ?? '',
      imagePath: map['image_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'action': action,
      'payload': payload,
      'status': status,
      'timestamp': timestamp,
      if (imagePath != null) 'image_path': imagePath,
    };
  }
}
