import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:one_one/components/hold_btn.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/core/shared/spacing.dart';
import 'package:one_one/models/friend.dart';
import 'package:one_one/providers/home_provider.dart';
import 'package:provider/provider.dart';
import '../providers/walkie_talkie_provider.dart';

class WalkieTalkieScreen extends StatefulWidget {
  const WalkieTalkieScreen({super.key});

  @override
  State<WalkieTalkieScreen> createState() => _WalkieTalkieScreenState();
}

class _WalkieTalkieScreenState extends State<WalkieTalkieScreen> {
  late final PageController centerSnapScrollController;
  bool isHolding = false;

  final nameController = TextEditingController();
  final targetCodeController = TextEditingController();
  final messageController = TextEditingController();

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
    nameController.dispose();
    targetCodeController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _logFirebaseIdToken(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        logger.debug('Firebase ID Token: $idToken');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase ID Token logged to console'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        logger.warning('No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authenticated user found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      logger.error('Error getting Firebase ID Token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    // final homeProvider = Provider.of<HomeProvider>(context);

    // return Scaffold(
    //   body: Stack(
    //     children: [
    //       BgContainer(
    //         isShaking: isHolding,
    //         displayMargin: isHolding,
    //         imageUrl: selectedAvatar?.photoUrl,
    //       ),
    //       Positioned.fill(
    //         top: null,
    //         bottom: 50,
    //         child: CenterSnapScroll(
    //           controller: centerSnapScrollController,
    //           children: [
    //             AddFrndBtn(),
    //             ...List.generate(
    //               homeProvider.friends.length,
    //               (index) {
    //                 final friend = homeProvider.friends[index];
    //                 return HoldBtn(
    //                   image: friend.photoUrl,
    //                   onHold: () {
    //                     setState(() {
    //                       isHolding = true;
    //                     });
    //                     if (friend.socketId != null) {
    //                       provider.startCall(friend.socketId!);
    //                     }
    //                   },
    //                   onRelease: () {
    //                     setState(() {
    //                       isHolding = false;
    //                     });
    //                     provider.disposeResources();
    //                   },
    //                 );
    //               }
    //             )
    //           ],
    //         ),
    //       ),
    //       // Positioned(
    //       //   bottom: 50,
    //       //   right: 0,
    //       //   left: 0,
    //       //   child: HoldBtn(
    //       //     image: "https://picsum.photos/200/300",
    //       //     onHold: () {
    //       //       setState(() {
    //       //         isHolding = true;
    //       //       });
    //       //       // widget.provider.startCall(widget.provider.connectedUserCode);
    //       //     },
    //       //     onRelease: () {
    //       //       setState(() {
    //       //         isHolding = false;
    //       //       });
    //       //       // widget.provider.disposeResources();
    //       //     },
    //       //   ),
    //       // )
    //     ],
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(
        title: const Text('OneOne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Friend'),
                  content: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter friend code',
                    ),
                    onSubmitted: (value) async {
                      if (value.isNotEmpty) {
                        final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
                        final response = await loc<ApiService>().post(
                          'friend/send-request',
                          body: {
                            "uniqueCode": value
                          },
                          headers: {
                            'Authorization': 'Bearer $idToken',
                          },
                        );
                        logger.debug(response);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Response: $response'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Log Firebase ID Token',
          ),
          IconButton(
            icon: const Icon(Icons.work),
            onPressed: () async {
              final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
              final response = await loc<ApiService>().get(
                'friend/list',
                headers: {
                  // 'Content-Type': 'application/json',
                  'Authorization': 'Bearer $idToken',
                },
              );
              logger.debug(idToken);
              logger.debug(response);
            },
            tooltip: 'Log Firebase ID Token',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _logFirebaseIdToken(context),
            tooltip: 'Log Firebase ID Token',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              loc<AuthService>().signOut();
            }
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Connection Status'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Name: ${provider.userName}'),
                      Text('Your Code: ${provider.uniqueCode}'),
                      Text('Connected To: ${provider.connectedUserName}'),
                      Text('Call Active: ${provider.isCallActive}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(Spacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UserInformationSection(
                    nameController: nameController,
                    provider: provider
                  ),
                  SizedBox(height: Spacing.s4),
                  _ConnectionSection(
                    targetCodeController: targetCodeController,
                    provider: provider
                  ),
                  // SizedBox(height: Spacing.s4),
                  // _ConnectedUsersSection(provider: provider),
                ],
              ),
            ),
          ),
          _CallControlSection(provider: provider),
        ],
      ),
    );
  }
}

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
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        onSubmitted: (value) async{
                          if (value.isNotEmpty) {
                            final String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
                            loc<ApiService>().post(
                              'friend/send-request',
                              body: {
                                "uniqueCode": value
                              },
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $idToken',
                              },
                            );
                          }
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await loc<ApiService>().get(
                            "friend/list",
                            authenticated: true
                          );
                        },
                        child: Text("Fetch Friends"),
                      ),
                      TextField(
                        onSubmitted: (value) async{
                          if (value.isNotEmpty) {
                            final String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
                            loc<ApiService>().post(
                              'friend/accept-request',
                              body: {
                                "uniqueCode": value
                              },
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $idToken',
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          );
        },
        radius: 70,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorScheme.of(context).surface
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

class _UserInformationSection extends StatelessWidget {
  const _UserInformationSection({
    required this.nameController,
    required this.provider,
  });

  final TextEditingController nameController;
  final WalkieTalkieProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
              ),
              onChanged: (value) => provider.userName = value,
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Your Code: ${provider.uniqueCode}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionSection extends StatelessWidget {
  const _ConnectionSection({
    required this.targetCodeController,
    required this.provider,
  });

  final TextEditingController targetCodeController;
  final WalkieTalkieProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter your name',
              ),
              controller: targetCodeController
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                if (targetCodeController.text.isNotEmpty) {
                  provider.connectToUser(
                    targetCodeController.text,
                    'Unknown User',
                  );
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlSection extends StatefulWidget {
  const _CallControlSection({
    required this.provider,
  });

  final WalkieTalkieProvider provider;

  @override
  State<_CallControlSection> createState() => _CallControlSectionState();
}

class _CallControlSectionState extends State<_CallControlSection> {
  ElevatedButton startCallBtn() {
    return ElevatedButton.icon(
      onPressed: widget.provider.connectedUserCode.isEmpty
        ? null
        : () => widget.provider.startCall(widget.provider.connectedUserCode),
      icon: const Icon(Icons.call),
      label: const Text('Start Call'),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
      ),
    );
  }

  ElevatedButton endCallBtn() {
    return ElevatedButton.icon(
      onPressed: widget.provider.disposeResources,
      icon: const Icon(Icons.call_end),
      label: const Text('End Call'),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.of(context).error,
        foregroundColor: ColorScheme.of(context).onError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          HoldBtn(
            image: "https://avatars.githubusercontent.com/u/130775015?v=4",
            onHold: () {
              widget.provider.startCall(widget.provider.connectedUserCode);
            },
            onRelease: () {
              // widget.provider.disposeResources();
            },
          )
          // if (!widget.provider.isCallActive)
          //   startCallBtn()
          // else
          //   endCallBtn(),
        ],
      ),
    );
  }
}