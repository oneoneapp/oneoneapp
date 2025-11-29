import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/models/friend.dart';
import 'package:one_one/providers/home_provider.dart';
import 'package:one_one/services/user_service.dart';
import 'package:one_one/components/online_status_dot.dart';
import 'package:provider/provider.dart';

class AddFrndBtn extends StatelessWidget {
  const AddFrndBtn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showBottomSheet(
            context: context,
            builder: (context) {
              return Page();
            }
          );
        },
        radius: 70,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorScheme.of(context).surfaceContainerLowest
          ),
          child: Icon(
            Icons.add,
            color: ColorScheme.of(context).onSurfaceVariant
          )
        ),
      ),
    );
  }
}

class Page extends StatelessWidget {
  const Page({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 40
      ),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.account_circle),
                onPressed: () => context.push('/profile'),
              ),
              SettingsBtn(),
            ],
          ),
          UserProfileSection(),
          AddFriendButton(),
          PendingRequests(),
          ...List.generate(
            homeProvider.friends.length,
            (index) {
              final friend = homeProvider.friends[index];
              return Consumer<HomeProvider>(
                builder: (context, homeProvider, child) {
                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(friend.photoUrl),
                        ),
                        if (friend.socketData?.isOnline ?? false)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: OnlineStatusDot(
                              isOnline: friend.socketData?.isOnline ?? false,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    title: Text(friend.name),
                    subtitle: Text(friend.uniqueCode)
                  );
                },
              );
            }
          )
        ],
      ),
    );
  }
}

class SettingsBtn extends StatelessWidget {
  const SettingsBtn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.settings),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Settings"),
              content: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: () => loc<AuthService>().signOut(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close")
                )
              ],
            );
          }
        );
      },
    );
  }
}

class UserProfileSection extends StatelessWidget {
  const UserProfileSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 15,
          bottom: 20,
          right: 10,
          top: 20
        ),
        child: FutureBuilder(
          future: UserService.getLocalUserData(),
          builder: (context, asyncSnapshot) {
            final data = asyncSnapshot.data;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data?['name'] ?? "User",
                      style: TextTheme.of(context).titleLarge,
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.only(
                        left: 8
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).secondaryContainer,
                        border: Border.all(
                          color: ColorScheme.of(context).onSecondaryContainer
                        ),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SelectableText(data?['uniqueCode'] ?? ""),
                          IconButton(
                            icon: Icon(Icons.copy),
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: data?['uniqueCode'] ?? ""));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Unique code copied to clipboard"),
                                )
                              );
                            },
                          )
                        ],
                      )
                    )
                  ],
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(data?['profilePic'] ?? ""),
                  radius: 40,
                )
              ],
            );
          }
        ),
      ),
    );
  }
}

class PendingRequests extends StatelessWidget {
  const PendingRequests({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    
    return ListTile(
      title: Text(
        "Pending requests",
        style: TextTheme.of(context).titleSmall,
      ),
      leading: Container(
        padding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12
        ),
        decoration: BoxDecoration(
          color: ColorScheme.of(context).secondary,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Text(
          homeProvider.pendingRequests.length.toString(),
          style: TextTheme.of(context).labelLarge?.copyWith(
            color: ColorScheme.of(context).onSecondary,
          ),
        )
      ),
      onTap: () {
        showBottomSheet(
          context: context,
          builder: (context) {
            return Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 40
                  ),
                  child: ListView(
                    children: [
                      ListTile(
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      if (homeProvider.pendingRequests.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.sizeOf(context).height * 0.3
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "No pending requests",
                                  style: TextTheme.of(context).titleMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                      ...List.generate(
                        homeProvider.pendingRequests.length,
                        (index) {
                          final friend = homeProvider.pendingRequests[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(friend.photoUrl),
                            ),
                            title: Text(friend.name),
                            subtitle: Text(friend.uniqueCode),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final String message = await homeProvider.acceptFriendRequest(friend.uniqueCode);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                      )
                                    );
                                  },
                                  icon: Icon(Icons.check, color: Colors.green)
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final String message = await homeProvider.declineFriendRequest(friend.uniqueCode);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                      )
                                    );
                                  },
                                  icon: Icon(Icons.close, color: Colors.red)
                                ),
                              ],
                            ),
                          );
                        }
                      )
                    ],
                  ),
                );
              }
            );
          }
        );
      },
    );
  }
}

class AddFriendButton extends StatefulWidget {
  const AddFriendButton({
    super.key,
  });

  @override
  State<AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<AddFriendButton> {
  late final TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 20
      ),
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorScheme.of(context).outlineVariant
        )
      ),
      child: ListTile(
        title: Text("Add Friend"),
        leading: Container(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.person_add,
            color: ColorScheme.of(context).onSecondary,
          )
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: "Enter Friend's Code"
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isEmpty) return;
                        final res = await loc<ApiService>().post(
                          'friend/send-request',
                          body: {
                            "uniqueCode": controller.text
                          },
                          authenticated: true,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (res.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Request sent successfully"),
                            )
                          );
                          final targetFrnd = Friend.fromMap(res.data['targetUser']);
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(
                                  "Friend Request Sent",
                                ),
                                content: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(targetFrnd.photoUrl),
                                  ),
                                  title: Text(targetFrnd.name),
                                  subtitle: Text(targetFrnd.uniqueCode),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("close")
                                  )
                                ],
                              );
                            }
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.data['message'] ?? 'Failed to send request'),
                            )
                          );
                        }
                      },
                      child: Text("Send request")
                    )
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }
}