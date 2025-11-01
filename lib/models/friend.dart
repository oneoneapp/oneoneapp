class Friend {
  final String id;
  final String name;
  final String photoUrl;
  final String uniqueCode;
  final String? socketId;
  final String? firebaseUid; // Firebase UID for socket mapping

  const Friend({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.uniqueCode,
    required this.socketId,
    this.firebaseUid,
  });

  factory Friend.fromMap(Map map) {
    return Friend(
      id: map['_id'],
      name: map['name'],
      photoUrl: map['photoUrl'],
      uniqueCode: map['uniqueCode'],
      socketId: map['socketId'],
      firebaseUid: map['firebaseUid'] ?? map['uid'], // Handle both field names
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'photoUrl': photoUrl,
      'uniqueCode': uniqueCode,
      'socketId': socketId,
      'firebaseUid': firebaseUid,
    };
  }
}