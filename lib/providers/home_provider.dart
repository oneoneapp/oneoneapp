import 'dart:async';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/models/enums.dart';
import 'package:one_one/models/friend.dart';
import 'package:one_one/models/speaker_event.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';

class HomeProvider extends ChangeNotifier {
  final WalkieTalkieProvider walkieTalkieProvider;
  late FriendsFetchStatus friendsFetchStatus;

  HomeProvider({
    required this.walkieTalkieProvider,
  }) {
    init();
  }

  late List subs = [];

  void init() {
    friendsFetchStatus = FriendsFetchStatus.idle;
    fetchFrndsList();
    subs = [
      walkieTalkieProvider.userPresenceStream.listen(_userPresenceListener),
      walkieTalkieProvider.userSpeakingStream.listen(_userSpeakingListener),
      Timer.periodic(Duration(seconds: 2), (_) {
        if (friendsFetchStatus == FriendsFetchStatus.loaded && _userPresenceQueue.isNotEmpty) {
          logger.debug("Processing user presence queue with ${_userPresenceQueue.length} items.");
          while (_userPresenceQueue.isNotEmpty) {
            final socketData = _userPresenceQueue.removeAt(0);
            _userPresenceListener(socketData);
          }
        }
      })
    ];
  }

  void _userPresenceListener(SocketData socketData) {
    if (friendsFetchStatus != FriendsFetchStatus.loaded) {
      logger.debug("Friends list not loaded yet. Moving user presence update to queue.");
      _userPresenceQueue.add(socketData);
      return;
    }
    if (_friends.containsUniqueCode(socketData.uniqueCode)) {
      final index = _friends.indexByUniqueCode(socketData.uniqueCode);
      _friends[index] = _friends[index].copyWith(
        socketData: socketData
      );
      logger.debug("Updated friend: ${_friends[index].toMap()}");  
      notifyListeners();
    } else if (_pendingRequests.containsUniqueCode(socketData.uniqueCode)) {
      final index = _pendingRequests.indexByUniqueCode(socketData.uniqueCode);
      _pendingRequests[index] = _pendingRequests[index].copyWith(
        socketData: socketData
      );
      logger.debug("Updated pending friend user presence: ${_pendingRequests[index].toMap()}");  
      notifyListeners();
    } else {
      logger.debug("User presence update for unknown user: ${socketData.uniqueCode}");
    }
  }

  void _userSpeakingListener(ActiveSpeakerEvent event) {
    if (_friends.containsSocketId(event.socketId)) {
      final index = _friends.indexBySocketId(event.socketId);
      _friends[index] = _friends[index].copyWith(
        socketData: _friends[index].socketData?.copyWith(
          speaking: event.speaking,
        )
      );
      logger.debug("Updated friend speaking status: ${_friends[index].toMap()}");  
      notifyListeners();
    }
  }

  final List<SocketData> _userPresenceQueue = [];
  final List<Friend> _friends = [];
  final List<Friend> _pendingRequests = [];

  List<Friend> get friends => _friends;
  List<Friend> get pendingRequests => _pendingRequests;

  void fetchFrndsList() async {
    friendsFetchStatus = FriendsFetchStatus.loading;
    notifyListeners();
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
      friendsFetchStatus = FriendsFetchStatus.loaded;
      notifyListeners();
    } catch (e) {
      friendsFetchStatus = FriendsFetchStatus.failure;
      notifyListeners();
      logger.error("Error fetching friends list: $e");
    }
  }

  Future<String> acceptFriendRequest(String uniqueCode) async {
    try {
      final res = await loc<ApiService>().post(
        'friend/accept-request',
        body: {
          "uniqueCode": uniqueCode
        },
        authenticated: true
      );
      if (res.statusCode != 200) return res.data['message'] ?? "";
      walkieTalkieProvider.updateFriendsSocketData();
      final index = _pendingRequests.indexByUniqueCode(uniqueCode);
      final friend = _pendingRequests.removeAt(index);
      _friends.add(friend);
      notifyListeners();
      return "Friend request accepted";
    } catch (e) {
      return "Failed to accept request";
    }
  }

  Future<String> declineFriendRequest(String uniqueCode) async {
    try {
      final res = await loc<ApiService>().post(
        'friend/decline-request',
        body: {
          "uniqueCode": uniqueCode
        },
        authenticated: true
      );
      if (res.statusCode != 200) return res.data['message'] ?? "";
      final index = _pendingRequests.indexByUniqueCode(uniqueCode);
      _pendingRequests.removeAt(index);
      notifyListeners();
      return "Friend request declined";
    } catch (e) {
      return "Failed to decline request";
    }
  }

  @override
  void dispose() {
    for (final sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }
}