export '../utils/friend.dart';

class Friend {
  final String id;
  final String name;
  final String photoUrl;
  final String uniqueCode;
  final SocketFriend? socketData;

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
    SocketFriend? socketData
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

class SocketFriend {
  final String name;
  final String firebaseUid;
  final String uniqueCode;
  final String? socketId;
  final bool speaking;

  SocketFriend({
    required this.name,
    required this.firebaseUid,
    required this.uniqueCode,
    this.socketId,
    this.speaking = false,
  });

  factory SocketFriend.fromMap(Map<String, dynamic> map) {
    return SocketFriend(
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

  SocketFriend copyWith({
    String? name,
    String? firebaseUid,
    String? uniqueCode,
    String? socketId,
    bool? speaking
  }) {
    return SocketFriend(
      name: name ?? this.name,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      socketId: socketId ?? this.socketId,
      speaking: speaking ?? this.speaking
    );
  }

  bool get isOnline => socketId?.isNotEmpty ?? false;
}