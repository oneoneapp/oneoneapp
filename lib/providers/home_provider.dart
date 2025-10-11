import 'package:flutter/material.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/models/friend.dart';

class HomeProvider extends ChangeNotifier {
  final List<Friend> _friends = [];
  final List<Friend> _pendingRequests = [];

  HomeProvider() {
    fetchFrndsList();
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
          _friends.add(Friend.fromMap(friend));
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