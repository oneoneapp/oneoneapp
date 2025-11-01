import 'package:flutter/material.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/models/friend.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';

class HomeProvider extends ChangeNotifier {
  final WalkieTalkieProvider walkieTalkieProvider;

  HomeProvider({
    required this.walkieTalkieProvider,
  }) {
    fetchFrndsList();
    // Listen to socket friends list updates for real-time status changes
    walkieTalkieProvider.addListener(_onWalkieTalkieUpdate);
  }

  final List<Friend> _friends = [];
  final List<Friend> _pendingRequests = [];

  void _onWalkieTalkieUpdate() {
    // When socket friends list updates, refresh the data to sync online status
    notifyListeners();
  }

  void fetchFrndsList() async {
    try {
      final res = await loc<ApiService>().get(
        "friend/list",
        authenticated: true
      );
      if (res.data["message"] == "Friends list retrieved successfully") {
        _friends.clear();
        _pendingRequests.clear();
        for (final friend in res.data["friends"]) {
          _friends.add(Friend.fromMap(friend));
        }
        for (final friend in res.data["pendingRequests"]) {
          _pendingRequests.add(Friend.fromMap(friend));
        }
      }
      notifyListeners();
    } catch (e) {
      // Handle error
    }
    
  }

  List<Friend> get friends => _friends;
  List<Friend> get pendingRequests => _pendingRequests;

  // Get online status for a friend using their Firebase UID
  bool isFriendOnline(String friendId) {
    // First try to find the friend in our list to get their Firebase UID
    try {
      final friend = _friends.firstWhere((f) => f.id == friendId);
      if (friend.firebaseUid != null) {
        return walkieTalkieProvider.isFriendOnline(friend.firebaseUid!);
      }
    } catch (e) {
      // Friend not found, continue with fallback
    }
    // Fallback: assume friendId is already the Firebase UID
    return walkieTalkieProvider.isFriendOnline(friendId);
  }

  // Get socket friend data by Firebase UID
  SocketFriend? getSocketFriend(String friendId) {
    // First try to find the friend in our list to get their Firebase UID
    try {
      final friend = _friends.firstWhere((f) => f.id == friendId);
      if (friend.firebaseUid != null) {
        return walkieTalkieProvider.getFriendByUid(friend.firebaseUid!);
      }
    } catch (e) {
      // Friend not found, continue with fallback
    }
    // Fallback: assume friendId is already the Firebase UID
    return walkieTalkieProvider.getFriendByUid(friendId);
  }

  // Get current socket code for calling a friend
  String? getFriendSocketCode(String friendId) {
    try {
      final friend = _friends.firstWhere((f) => f.id == friendId);
      if (friend.firebaseUid != null) {
        // For now, return the stored socketId as we need server support for Firebase UID mapping
        return friend.socketId;
      }
    } catch (e) {
      // Friend not found
    }
    return null;
  }

  @override
  void dispose() {
    walkieTalkieProvider.removeListener(_onWalkieTalkieUpdate);
    super.dispose();
  }
}