import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';
import 'package:one_one/components/online_status_dot.dart';

class FriendsListPage extends StatelessWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.black,
      body: Consumer<WalkieTalkieProvider>(
        builder: (context, provider, child) {
          if (provider.friendsList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add friends to start chatting',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.friendsList.length,
            itemBuilder: (context, index) {
              final friend = provider.friendsList[index];
              return FriendListTile(friend: friend);
            },
          );
        },
      ),
    );
  }
}

class FriendListTile extends StatelessWidget {
  final SocketFriend friend;

  const FriendListTile({
    super.key,
    required this.friend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[600],
              child: Text(
                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: OnlineStatusDot(
                isOnline: friend.isOnline,
                size: 16,
              ),
            ),
          ],
        ),
        title: Text(
          friend.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: OnlineStatusRow(
          isOnline: friend.isOnline,
          textStyle: TextStyle(
            color: friend.isOnline ? Colors.green : Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: friend.isOnline
            ? IconButton(
                icon: const Icon(
                  Icons.call,
                  color: Colors.green,
                ),
                onPressed: () {
                  // TODO: Implement call functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${friend.name}...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              )
            : const Icon(
                Icons.call,
                color: Colors.grey,
              ),
      ),
    );
  }
}