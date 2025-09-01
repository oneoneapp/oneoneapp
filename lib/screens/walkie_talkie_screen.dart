import 'package:flutter/material.dart';
import 'package:one_one/components/hold_btn.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/shared/spacing.dart';
import 'package:provider/provider.dart';
import '../providers/walkie_talkie_provider.dart';

class WalkieTalkieScreen extends StatefulWidget {
  const WalkieTalkieScreen({super.key});

  @override
  State<WalkieTalkieScreen> createState() => _WalkieTalkieScreenState();
}

class _WalkieTalkieScreenState extends State<WalkieTalkieScreen> {
  final nameController = TextEditingController();
  final targetCodeController = TextEditingController();
  final messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalkieTalkieProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OneOne'),
        actions: [
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

  @override
  void dispose() {
    nameController.dispose();
    targetCodeController.dispose();
    messageController.dispose();
    super.dispose();
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