export '../utils/friend.dart';

class Friend {
  final String id;
  final String name;
  final String photoUrl;
  final String uniqueCode;
  final SocketData? socketData;

  const Friend({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.uniqueCode,
    this.socketData
  });

  factory Friend.fromMap(Map map) {
    return Friend(
      id: map['_id'],
      name: map['name'],
      photoUrl: map['photoUrl'],
      uniqueCode: map['uniqueCode']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'photoUrl': photoUrl,
      'uniqueCode': uniqueCode,
      'socketData': socketData?.toMap()
    };
  }

  Friend copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? uniqueCode,
    SocketData? socketData
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      socketData: socketData ?? this.socketData
    );
  }
}

class SocketData {
  final String name;
  final String firebaseUid;
  final String uniqueCode;
  final String? socketId;
  final bool speaking;

  SocketData({
    required this.name,
    required this.firebaseUid,
    required this.uniqueCode,
    this.socketId,
    this.speaking = false,
  });

  factory SocketData.fromMap(Map<String, dynamic> map) {
    return SocketData(
      name: map['name'] ?? '',
      firebaseUid: map['uid'] ?? '',
      uniqueCode: map['uniqueCode'],
      socketId: map['socketId']
    );
  }

  Map <String, dynamic> toMap() {
    return {
      'name': name,
      'uid': firebaseUid,
      'uniqueCode': uniqueCode,
      'socketId': socketId,
    };
  }

  SocketData copyWith({
    String? name,
    String? firebaseUid,
    String? uniqueCode,
    String? socketId,
    bool? speaking
  }) {
    return SocketData(
      name: name ?? this.name,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      socketId: socketId ?? this.socketId,
      speaking: speaking ?? this.speaking
    );
  }

  bool get isOnline => socketId?.isNotEmpty ?? false;
}