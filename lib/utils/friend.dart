import 'package:one_one/models/friend.dart';

extension FriendListUtils on List<Friend> {
  Friend? getByUniqueCode(String uniqueCode) {
    try {
      return firstWhere((friend) => friend.uniqueCode == uniqueCode);
    } catch (e) {
      return null;
    }
  }

  Friend? getBySocketId(String socketId) {
    try {
      return firstWhere((friend) => friend.socketData?.socketId == socketId);
    } catch (e) {
      return null;
    }
  }

  int indexByUniqueCode(String uniqueCode) {
    return indexWhere((friend) => friend.uniqueCode == uniqueCode);
  }

  int indexBySocketId(String socketId) {
    return indexWhere((friend) => friend.socketData?.socketId == socketId);
  }

  bool containsUniqueCode(String uniqueCode) {
    return any((friend) => friend.uniqueCode == uniqueCode);
  }

  bool containsSocketId(String socketId) {
    return any((friend) => friend.socketData?.socketId == socketId);
  }
}