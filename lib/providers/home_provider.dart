import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/models/enums.dart';
import 'package:one_one/models/friend.dart';
import 'package:one_one/models/speaker_event.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeProvider extends ChangeNotifier {
  final WalkieTalkieProvider walkieTalkieProvider;
  late FriendsFetchStatus friendsFetchStatus;

  HomeProvider({
    required this.walkieTalkieProvider,
  }) {
    friendsFetchStatus = FriendsFetchStatus.idle;
  }

  late List subs = [];

  Future<void> init() async {
    if (friendsFetchStatus != FriendsFetchStatus.idle) return;
    fetchFrndsList();
    await walkieTalkieProvider.initialize();
    subs = [
      walkieTalkieProvider.userPresenceStream.listen(_userPresenceListener),
      walkieTalkieProvider.userSpeakingStream.listen(_userSpeakingListener)
    ];
  }

  void _userPresenceListener(SocketData socketData) {
    if (friendsFetchStatus != FriendsFetchStatus.loaded) {
      logger.error("Friends list not loaded yet");
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

  final List<Friend> _friends = [];
  final List<Friend> _pendingRequests = [];

  static const String _friendsCacheKey = 'friends_list_cache';

  List<Friend> get friends => _friends;
  List<Friend> get pendingRequests => _pendingRequests;

  void fetchFrndsList() async {
    friendsFetchStatus = FriendsFetchStatus.loading;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    bool hadCache = false;

    // Try to load cached friends list first and update UI immediately
    try {
      final cached = prefs.getString(_friendsCacheKey);
      if (cached != null && cached.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(cached);
        _friends.clear();
        _pendingRequests.clear();
        if (data['friends'] is List) {
          for (final friend in data['friends']) {
            _friends.add(Friend.fromMap(Map<String, dynamic>.from(friend)));
          }
        }
        if (data['pendingRequests'] is List) {
          for (final friend in data['pendingRequests']) {
            _pendingRequests.add(Friend.fromMap(Map<String, dynamic>.from(friend)));
          }
        }
        friendsFetchStatus = FriendsFetchStatus.loaded;
        notifyListeners();
        walkieTalkieProvider.updateFriendsSocketData();
        hadCache = true;
      }
    } catch (e) {
      logger.error("Error reading cached friends list: $e");
    }

    // fetch the latest list from the server, cache it and update UI
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

        // Cache the fresh response
        try {
          final cacheObj = {
            'friends': res.data['friends'],
            'pendingRequests': res.data['pendingRequests'],
            'cachedAt': DateTime.now().toIso8601String(),
          };
          await prefs.setString(_friendsCacheKey, json.encode(cacheObj));
        } catch (e) {
          logger.error("Error caching friends list: $e");
        }

        friendsFetchStatus = FriendsFetchStatus.loaded;
        notifyListeners();
        walkieTalkieProvider.updateFriendsSocketData();
      } else {
        if (!hadCache) {
          friendsFetchStatus = FriendsFetchStatus.failure;
          notifyListeners();
        }
      }
    } catch (e) {
      if (!hadCache) {
        friendsFetchStatus = FriendsFetchStatus.failure;
        notifyListeners();
      }
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

  void updateFriendRequestsFromNotification(Map data) {
    if (_pendingRequests.containsUniqueCode(data["uniqueCode"])) return;
    _pendingRequests.add(Friend.fromMap(data));
    notifyListeners();
  }

  void updateFriendsFromNotification(Map data) {
    if (friends.containsUniqueCode(data["uniqueCode"])) return;
    _friends.add(Friend.fromMap(data));
    walkieTalkieProvider.updateFriendsSocketData();
    notifyListeners();
  }

  void reset() {
    for (final sub in subs) {
      sub.cancel();
    }
    _friends.clear();
    _pendingRequests.clear();
    friendsFetchStatus = FriendsFetchStatus.idle;
    walkieTalkieProvider.reset();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}