class Friend {
  final String id;
  final String name;
  final String photoUrl;
  final String uniqueCode;
  final String? socketId;

  const Friend({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.uniqueCode,
    required this.socketId
  });

  factory Friend.fromMap(Map map) {
    return Friend(
      id: map['_id'],
      name: map['name'],
      photoUrl: map['photoUrl'],
      uniqueCode: map['uniqueCode'],
      socketId: map['socketId']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'photoUrl': photoUrl,
      'uniqueCode': uniqueCode,
      'socketId': socketId
    };
  }
}