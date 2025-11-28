import 'package:flutter/material.dart';
import 'package:one_one/components/add_frnd_btn.dart';
import 'package:one_one/components/bg_container.dart';
import 'package:one_one/components/center_snap_scroll.dart';
import 'package:one_one/components/friend_btn.dart';
import 'package:one_one/components/speaking_status_dot.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/core/shared/spacing.dart';
import 'package:one_one/models/enums.dart';
import 'package:one_one/models/friend.dart';
import 'package:one_one/providers/home_provider.dart';
import 'package:one_one/services/user_service.dart';
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
  CallConnectionState? callConnectionState;

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
            isShaking: isHolding && callConnectionState == CallConnectionState.connecting,
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: MediaQuery.of(context).padding.right + 15,
            child: Column(
              children: List.generate(
                homeProvider.friends.speaking.length, 
                (index) {
                  final Friend friend = homeProvider.friends.speaking[index];
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: Spacing.s1
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorScheme.of(context).primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ColorScheme.of(context).onPrimary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SpeakingStatusDot(),
                        const SizedBox(width: Spacing.s2),
                        Text(
                          friend.name,
                          style: TextTheme.of(context).titleSmall?.copyWith(
                            color: ColorScheme.of(context).surface,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              )
            ),
          ),
          Positioned.fill(
            top: null,
            bottom: 200,
            child: Column(
              children: [
                if (selectedAvatar != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selectedAvatar?.socketData?.speaking ?? false) ...[
                        SpeakingStatusDot(
                          isSpeaking: selectedAvatar?.socketData?.speaking ?? false,
                        ),
                        const SizedBox(width: Spacing.s2),
                      ],
                      Text(
                        selectedAvatar?.name ?? "",
                        style: TextTheme.of(context).headlineSmall,
                      ),
                    ],
                  ),
                if (callConnectionState != null)
                  Container(
                    padding: const EdgeInsets.all(Spacing.s1),
                    decoration: BoxDecoration(
                      color: ColorScheme.of(context).secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      callConnectionState == CallConnectionState.connecting
                        ? 'Connecting...'
                        : callConnectionState == CallConnectionState.connected
                          ? 'Connected'
                          : 'Call Failed',
                      style: TextTheme.of(context).titleSmall?.copyWith(
                        color: ColorScheme.of(context).onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            top: null,
            bottom: 50,
            child: Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                return CenterSnapScroll(
                  controller: centerSnapScrollController,
                  children: [
                    AddFrndBtn(),
                    ...frndsAvatars(homeProvider, provider)
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> startCall(String uniqueCode, HomeProvider homeProvider, WalkieTalkieProvider provider) async {
    Friend friend = homeProvider.friends.getByUniqueCode(uniqueCode)!;
    setState(() {
      isHolding = true;
    });
    final String? socketId = friend.socketData?.socketId;
    if (socketId != null) {
      logger.info("Calling ${friend.name}");
      callConnectionState = CallConnectionState.connecting;
      setState(() {});
      callConnectionState = await provider.startCall(socketId);
      setState(() {});
    } else {
      callConnectionState = CallConnectionState.connecting;
      setState(() {});
      final res = await loc<ApiService>().post(
        "fcm/wakeup-friend",
        authenticated: true,
        body: {
          "friendUniqueCode": friend.uniqueCode, 
          "title": "Pick up the phone bitch!",
          "body" : "${(await UserService.getLocalUserData())?["name"]} is calling"
        }
      );
      
      if (res.statusCode == 200) {
        while (homeProvider.friends.getByUniqueCode(uniqueCode)?.socketData?.socketId == null) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        friend = homeProvider.friends.getByUniqueCode(uniqueCode)!;
        
        if (friend.socketData?.socketId != null) {
          callConnectionState = await provider.startCall(friend.socketData!.socketId!);
          setState(() {});
        }
      }
    }
  }

  List<Widget> frndsAvatars(HomeProvider homeProvider, WalkieTalkieProvider provider) {
    return List.generate(
      homeProvider.friends.length,
      (index) {
        final Friend friend = homeProvider.friends[index];
        
        return FriendBtn(
          friend: friend,
          enabled: selectedAvatar?.id == friend.id,
          onHold: () async {
            logger.info("Hold btn holded");
            startCall(friend.uniqueCode, homeProvider, provider);
          },
          onHolding: () async {
            logger.info("Hold btn put to Holding");
            if (isHolding) return;
            startCall(friend.uniqueCode, homeProvider, provider);
          },
          onRelease: () {
            logger.info("Hold btn Released");
            setState(() {
              isHolding = false;
            });
            logger.info("Ending call ${friend.name}");
            provider.endCall(friend.socketData?.socketId ?? '');
            callConnectionState = null;
            setState(() {});
          },
        );
      }
    );
  }
}