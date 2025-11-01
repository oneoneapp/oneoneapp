import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_one/components/add_frnd_btn.dart';
import 'package:one_one/components/bg_container.dart';
import 'package:one_one/components/center_snap_scroll.dart';
import 'package:one_one/components/hold_btn.dart';
import 'package:one_one/models/friend.dart';
import 'package:one_one/providers/home_provider.dart';
import 'package:provider/provider.dart';
import '../providers/walkie_talkie_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController centerSnapScrollController;
  bool isHolding = false;

  @override
  void initState() {
    centerSnapScrollController = PageController(
      initialPage: 1,
      viewportFraction: 0.3
    );
    centerSnapScrollController.addListener(listener);
    super.initState();
  }

  void listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    centerSnapScrollController.removeListener(listener);
    centerSnapScrollController.dispose();
    super.dispose();
  }

  Friend? get selectedAvatar {
    if (centerSnapScrollController.hasClients) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final int index = (centerSnapScrollController.page ?? 1).toInt() - 1;
      if (index >= 0 && index < homeProvider.friends.length) {
        return homeProvider.friends[index];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalkieTalkieProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          BgContainer(
            isShaking: isHolding,
            displayMargin: isHolding,
            imageUrl: selectedAvatar?.photoUrl,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black
                ],
                stops: const [0.1, 0.9],
              )
            ),
          ),
          // Profile icon in top left
          Positioned(
            top: 60,
            left: 20,
            child: GestureDetector(
              onTap: () {
                context.push('/profile');
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          // Friends list icon in top right
          Positioned(
            top: 60,
            right: 20,
            child: GestureDetector(
              onTap: () {
                context.push('/friends');
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Consumer<WalkieTalkieProvider>(
                  builder: (context, provider, child) {
                    final onlineFriendsCount = provider.friendsList
                        .where((friend) => friend.isOnline)
                        .length;
                    
                    return Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        if (onlineFriendsCount > 0)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$onlineFriendsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: null,
            bottom: 50,
            child: Consumer<WalkieTalkieProvider>(
              builder: (context, walkieTalkieProvider, child) {
                return CenterSnapScroll(
                  controller: centerSnapScrollController,
                  children: [
                    AddFrndBtn(),
                    ...frndsAvatars(homeProvider, walkieTalkieProvider)
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> frndsAvatars(HomeProvider homeProvider, WalkieTalkieProvider provider) {
    return List.generate(
      homeProvider.friends.length,
      (index) {
        final friend = homeProvider.friends[index];
        
        // Check if friend is online by matching firebaseUid
        bool isOnline = false;
        if (friend.firebaseUid != null) {
          isOnline = provider.friendsList
              .any((socketFriend) => socketFriend.uid == friend.firebaseUid && socketFriend.isOnline);
        }
        
        return HoldBtn(
          image: friend.photoUrl,
          isOnline: isOnline,
          onHold: () {
            setState(() {
              isHolding = true;
            });
            final socketCode = homeProvider.getFriendSocketCode(friend.id);
            if (socketCode != null) {
              provider.startCall(socketCode);
            }
          },
          onHolding: () {
            setState(() {
              isHolding = true;
            });
            final socketCode = homeProvider.getFriendSocketCode(friend.id);
            if (socketCode != null) {
              provider.startCall(socketCode);
            }
          },
          onRelease: () {
            setState(() {
              isHolding = false;
            });
            // provider.disposeResources();
          },
        );
      }
    );
  }
}