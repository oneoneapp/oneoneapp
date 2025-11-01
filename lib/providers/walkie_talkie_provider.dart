import 'dart:async';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/baseurl.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Friend model for socket friends data
class SocketFriend {
  final String name;
  final String uid;
  final String status; // 'online' or 'offline'

  SocketFriend({
    required this.name,
    required this.uid,
    required this.status,
  });

  factory SocketFriend.fromMap(Map<String, dynamic> map) {
    return SocketFriend(
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      status: map['status'] ?? 'offline',
    );
  }

  SocketFriend copyWith({
    String? name,
    String? uid,
    String? status,
    bool? isOnline,
  }) {
    return SocketFriend(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      status: isOnline != null ? (isOnline ? 'online' : 'offline') : (status ?? this.status),
    );
  }

  bool get isOnline => status == 'online';
}

class WalkieTalkieProvider extends ChangeNotifier {
  late Socket socket;
  late StreamController onConnectedUser;
  late StreamController onDisconnectedUser;

  String uniqueCode = '';
  List<SocketFriend> _friendsList = [];

  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;

  bool isCallActive = false;
  bool isConnected = false;

  // Getter for friends list
  List<SocketFriend> get friendsList => _friendsList;

  Future<void> initialize() async {
    onConnectedUser = StreamController.broadcast();
    onDisconnectedUser = StreamController.broadcast();
    await _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    try {
      socket = io(
        baseUrl,
        {
          'transports': ['websocket'],
          'autoConnect': true,
          'forceNew': true,
          'reconnection': true,
          'reconnectionAttempts': 10000,
        }
      );
      socket.connect();

      socket.onConnect((_) {
        isConnected = true;
        final String firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        logger.debug(firebaseUid);
        socket.emit('connect-user',{
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
          'uid': firebaseUid,
        });

        socket.emit('get-friends-list',{
          'uid': firebaseUid,
        });

        logger.info('Socket connected');
      });
      socket.onDisconnect((_) {
        isConnected = false;
        logger.info('Socket disconnected');
      });

      _setupSocketListeners();
      _setupWebRTCListeners();
      socket.connect();
    } catch (e) {
      logger.error('Socket initialization error: $e');
    }
  }

  void _setupSocketListeners() {
    socket.on('socketId', (code) {
      logger.debug('socketId created:: $code');
      uniqueCode = code;
      notifyListeners();
    });

  socket.on('user-connected', (data) {
    logger.debug('User connected: $data');
    // Update the friend's status to online if they're in your friends list
    _updateFriendStatus(data['uid'], true);
    onConnectedUser.add(data);
    notifyListeners();
  });

  socket.on('user-disconnected', (data) {
    logger.debug('User disconnected: $data');
    // Update the friend's status to offline if they're in your friends list
    _updateFriendStatus(data['uid'], false);
    onDisconnectedUser.add(data); // You probably want a separate stream for disconnections
    notifyListeners();
  });

    socket.on('friends-list', (data) {
      logger.debug('Friends list received: $data');
      _updateFriendsList(data);
      notifyListeners();
    });
  }

void _updateFriendStatus(String uid, bool isOnline) {
  try {
    final friendIndex = _friendsList.indexWhere((friend) => friend.uid == uid);
    if (friendIndex != -1) {
      // Update the friend's online status
      _friendsList[friendIndex] = _friendsList[friendIndex].copyWith(isOnline: isOnline);
      logger.debug('Updated friend $uid status to ${isOnline ? "online" : "offline"}');
    }
  } catch (e) {
    logger.error('Error updating friend status: $e');
  }
}

  void _updateFriendsList(dynamic data) {
    try {
      _friendsList.clear();
      if (data is List) {
        for (var friendData in data) {
          if (friendData is Map<String, dynamic>) {
            _friendsList.add(SocketFriend.fromMap(friendData));
          }
        }
      }
      logger.debug('Updated friends list: ${_friendsList.length} friends');
    } catch (e) {
      logger.error('Error updating friends list: $e');
    }
  }

  // Method to get friend's online status by UID
  bool isFriendOnline(String uid) {
    try {
      final friend = _friendsList.firstWhere((friend) => friend.uid == uid);
      return friend.isOnline;
    } catch (e) {
      return false; // Friend not found or offline
    }
  }

  // Method to get friend by UID
  SocketFriend? getFriendByUid(String uid) {
    try {
      return _friendsList.firstWhere((friend) => friend.uid == uid);
    } catch (e) {
      return null;
    }
  }

  // Method to start call using Firebase UID (this might need server support)
  Future<void> startCallByUid(String firebaseUid, {bool audio = true}) async {
    // For now, we'll need to use the socketId if available
    // This is a placeholder - the server should ideally support calling by Firebase UID
    logger.warning('startCallByUid called with $firebaseUid - server should support this');
    // TODO: Implement server-side support for calling by Firebase UID
  }

  void _setupWebRTCListeners() {
    socket.on('offer', (data) async {
      logger.debug('Offer received');
      logger.debug(data);
      if (data['receiver'] == uniqueCode) {
        await receiveCall(data['sdp'], data['sender']);
      }
    });

    socket.on('answer', (data) async {
      logger.debug('Answer recieved');
      logger.debug(data);
      if (data['receiver'] == uniqueCode) {
        // handle answer
        await peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['sdp'], 'answer'),
        );
      }
    });

    socket.on('ice-candidate', (data) async {
      logger.info('ICE candidate received');
      logger.debug(data);
      if (data['receiver'] == uniqueCode) {
        // handle ICE candidate
        await peerConnection?.addCandidate(
          RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ),
        );
      }
    });
  }

  Future<void> _initializePeerConnection(String userCode, {bool audio = true}) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan'
    };

    peerConnection = await createPeerConnection(config);

    peerConnection!.onIceCandidate = (candidate) {
      socket.emit('ice-candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'sender': uniqueCode,
        'receiver': userCode,
      });
      logger.info('ICE candidate sent');
    };

    peerConnection!.onTrack = (event) {
      remoteStream = event.streams[0];
      notifyListeners();
    };

    if (audio) {
      await _addLocalStreamToPeer();
    }
  }

  Future<void> _addLocalStreamToPeer() async {
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false
    });
    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });
  }

  Future<void> startCall(String code, {bool audio = true}) async {
    await _initializePeerConnection(code, audio: audio);
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    socket.emit('offer', {
      'sdp': offer.sdp,
      'sender': uniqueCode,
      'receiver': code,
    });

    isCallActive = true;
    notifyListeners();
  }

  Future<void> receiveCall(String sdp, String sender) async {
    await _initializePeerConnection(sender);
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );

    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    socket.emit('answer', {
      'sdp': answer.sdp,
      'sender': uniqueCode,
      'receiver': sender,
    });

    isCallActive = true;
    notifyListeners();
  }

  void endCall() {
    localStream?.dispose();
    remoteStream?.dispose();
    peerConnection?.dispose();
    isCallActive = false;
    notifyListeners();
  }

  bool get isMuted {
    if (localStream == null) return false;
    return !(localStream!.getAudioTracks().first.enabled);
  }

  void muteCall() {
    localStream?.getAudioTracks().forEach((track) {
      track.enabled = !track.enabled;
    });
    notifyListeners();
  }

  @override
  void dispose() {
    endCall();
    onConnectedUser.close();
    onDisconnectedUser.close();
    socket.disconnect();
    super.dispose();
  }
}
