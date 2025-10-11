import 'package:flutter/material.dart';
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
      final int index = (centerSnapScrollController.page ?? 0).toInt() - 1;
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
          Positioned.fill(
            top: null,
            bottom: 50,
            child: CenterSnapScroll(
              controller: centerSnapScrollController,
              children: [
                AddFrndBtn(),
                ...frndsAvatars(homeProvider, provider)
              ],
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
        return HoldBtn(
          image: friend.photoUrl,
          onHold: () {
            setState(() {
              isHolding = true;
            });
            if (friend.socketId != null) {
              provider.startCall(friend.socketId!);
            }
          },
          onHolding: () {
            setState(() {
              isHolding = true;
            });
            if (friend.socketId != null) {
              provider.startCall(friend.socketId!);
            }
          },
          onRelease: () {
            setState(() {
              isHolding = false;
            });
            provider.disposeResources();
          },
        );
      }
    );
  }
}