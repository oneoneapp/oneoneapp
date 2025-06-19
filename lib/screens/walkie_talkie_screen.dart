// lib/screens/walkie_talkie_screen.dart

import 'package:flutter/material.dart';
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
        title: const Text('Walkie-Talkie App'),
        actions: [
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User Information Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Your Name',
                                border: OutlineInputBorder(),
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
                    ),
                    const SizedBox(height: 16),

                    // Connection Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: targetCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Connect to Code',
                                border: OutlineInputBorder(),
                              ),
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
                    ),
                    const SizedBox(height: 16),

                    // Connected Users Section
                    Expanded(
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Connected Users',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: provider.connectedUsers.length,
                                itemBuilder: (context, index) {
                                  final user = provider.connectedUsers[index];
                                  return ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(user['name'] ?? 'Unknown'),
                                    subtitle: Text('Code: ${user['code']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.call),
                                      onPressed: () {
                                        provider.connectToUser(
                                          user['code'] ?? '',
                                          user['name'] ?? '',
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Call Control Section
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!provider.isCallActive)
                    ElevatedButton.icon(
                      onPressed: provider.connectedUserCode.isEmpty
                          ? null
                          : () => provider.startCall(provider.connectedUserCode),
                      icon: const Icon(Icons.call),
                      label: const Text('Start Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: provider.disposeResources,
                      icon: const Icon(Icons.call_end),
                      label: const Text('End Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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