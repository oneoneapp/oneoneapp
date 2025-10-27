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
    walkieTalkieProvider.onConnectedUser.stream.listen((data) {
      fetchFrndsList();
    });
  }

  final List<Friend> _friends = [];
  final List<Friend> _pendingRequests = [];

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
}