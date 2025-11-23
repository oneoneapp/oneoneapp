import 'dart:async';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/baseurl.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/models/friend.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalkieTalkieProvider extends ChangeNotifier {
  late Socket socket;
  late StreamController<SocketFriend> userPresenceController;
  Stream<SocketFriend> get userPresenceStream => userPresenceController.stream;

  String uniqueCode = '';

  // single local microphone stream (shared)
  MediaStream? localStream;
  // multiple remote streams keyed by remote user code
  final Map<String, MediaStream> remoteStreams = {};
  // one RTCPeerConnection per remote user (both incoming and outgoing)
  final Map<String, RTCPeerConnection> peerConnections = {};
  // keep track of senders added for each peer so we can remove/replace when we stop transmitting
  final Map<String, List<RTCRtpSender>> _peerSenders = {};

  bool isCallActive = false;
  bool isConnected = false;
  String? selectedTarget;

  Future<void> initialize() async {
    userPresenceController = StreamController.broadcast();
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
        },
      );
      socket.connect();

      socket.onConnect((_) {
        isConnected = true;
        final String firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        logger.debug(firebaseUid);
        socket.emit('connect-user', {
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
          'uid': firebaseUid,
        });

        socket.emit('get-friends-list', {
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
      final friend = SocketFriend.fromMap(data);
      userPresenceController.add(friend);
      notifyListeners();
    });

    socket.on('user-disconnected', (data) {
      logger.debug('User disconnected: $data');
      final friend = SocketFriend.fromMap(data);
      userPresenceController.add(friend);
      notifyListeners();
    });

    socket.on('friends-list', (data) {
      logger.debug('Friends list received: $data');
      final List<SocketFriend> friendsList = [];
      for (var friendData in data) {
        if (friendData is Map<String, dynamic>) {
          friendsList.add(SocketFriend.fromMap(friendData));
        }
      }
      for (final friend in friendsList) {
        userPresenceController.add(friend);
      }
      notifyListeners();
    });
  }

  void _setupWebRTCListeners() {
    socket.on('offer', (data) async {
      logger.debug('Offer received: $data');
      final sender = data['sender'] as String;
      final receiver = data['receiver'] as String;
      if (receiver != uniqueCode) return;

      // ensure local stream exists
      await _ensureLocalStream();
      // create or reuse peer for sender
      final pc = await _createPeerIfNeeded(sender);
      // set remote description and answer
      await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'offer'));

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      socket.emit('answer', {
        'sdp': answer.sdp,
        'sender': uniqueCode,
        'receiver': sender,
      });

      isCallActive = true;
      notifyListeners();
    });

    socket.on('answer', (data) async {
      logger.debug('Answer received: $data');
      final sender = data['sender'] as String;
      final receiver = data['receiver'] as String;
      if (receiver != uniqueCode) return;
      final pc = peerConnections[sender];
      if (pc == null) {
        logger.warning('Received answer for unknown peer $sender');
        return;
      }
      await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
    });

    socket.on('ice-candidate', (data) async {
      logger.info('ICE candidate received: $data');
      final from = data['sender'] as String;
      final to = data['receiver'] as String;
      if (to != uniqueCode) return;
      final pc = peerConnections[from];
      if (pc == null) {
        logger.warning('ICE candidate for unknown peer $from');
        return;
      }
      try {
        await pc.addCandidate(RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        ));
      } catch (e) {
        logger.error('Failed to add ICE candidate for $from: $e');
      }
    });
  }

  Future<void> _ensureLocalStream() async {
    if (localStream != null) return;
    localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
  }

  Future<RTCPeerConnection> _createPeerIfNeeded(String peerId) async {
    if (peerConnections.containsKey(peerId)) return peerConnections[peerId]!;

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan'
    };

    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) {
      socket.emit('ice-candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'sender': uniqueCode,
        'receiver': peerId,
      });
      logger.info('ICE candidate sent to $peerId');
    };

    pc.onTrack = (event) {
      logger.debug('onTrack from $peerId');
      if (event.streams.isNotEmpty) {
        remoteStreams[peerId] = event.streams[0];
        notifyListeners();
      }
    };

    pc.onConnectionState = (state) {
      logger.debug('Peer $peerId connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _closePeer(peerId);
      }
    };

    peerConnections[peerId] = pc;
    _peerSenders[peerId] = [];
    return pc;
  }

  Future<void> startCall(String peerCode) async {
    await _ensureLocalStream();
    final pc = await _createPeerIfNeeded(peerCode);

    // add local audio track now so the other side hears when you press mic
    // note: addTrack returns RTCRtpSender which we store so we can remove later
    final audioSenders = <RTCRtpSender>[];
    for (final track in localStream!.getAudioTracks()) {
      final sender = await pc.addTrack(track, localStream!);
      audioSenders.add(sender);
    }
    _peerSenders[peerCode] = audioSenders;

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    socket.emit('offer', {
      'sdp': offer.sdp,
      'sender': uniqueCode,
      'receiver': peerCode,
    });

    selectedTarget = peerCode;
    isCallActive = true;
    notifyListeners();
  }

  Future<void> answerCall(String peerCode) async {
    await _ensureLocalStream();
    final pc = await _createPeerIfNeeded(peerCode);
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    socket.emit('answer', {
      'sdp': answer.sdp,
      'sender': uniqueCode,
      'receiver': peerCode,
    });
    isCallActive = true;
    notifyListeners();
  }

  Future<void> attachMicrophoneTo(String targetCode) async {
    await _ensureLocalStream();
    // if already attached to a different target, detach there first
    if (selectedTarget != null && selectedTarget != targetCode) {
      await detachMicrophoneFrom(selectedTarget!);
    }

    final pc = await _createPeerIfNeeded(targetCode);
    // if we already have senders for this peer, avoid duplicate adds
    if ((_peerSenders[targetCode] ?? []).isNotEmpty) {
      selectedTarget = targetCode;
      notifyListeners();
      return;
    }

    final audioSenders = <RTCRtpSender>[];
    for (final track in localStream!.getAudioTracks()) {
      final sender = await pc.addTrack(track, localStream!);
      audioSenders.add(sender);
    }
    _peerSenders[targetCode] = audioSenders;
    selectedTarget = targetCode;
    notifyListeners();
  }

  Future<void> detachMicrophoneFrom(String targetCode) async {
    final pc = peerConnections[targetCode];
    if (pc == null) return;
    final senders = _peerSenders[targetCode] ?? [];
    for (final s in senders) {
      try {
        await s.replaceTrack(null);
      } catch (e) {
        try {
          await pc.removeTrack(s);
        } catch (_) {}
      }
    }
    _peerSenders[targetCode] = [];
    if (selectedTarget == targetCode) selectedTarget = null;
    notifyListeners();
  }

  /// end/close a single peer
  Future<void> _closePeer(String peerId) async {
    try {
      await detachMicrophoneFrom(peerId);
    } catch (_) {}
    final pc = peerConnections.remove(peerId);
    try {
      await pc?.close();
      await pc?.dispose();
    } catch (_) {}
    final r = remoteStreams.remove(peerId);
    try {
      await r?.dispose();
    } catch (_) {}
    _peerSenders.remove(peerId);
    notifyListeners();
  }

  void endAllCalls() {
    for (final peerId in List<String>.from(peerConnections.keys)) {
      _closePeer(peerId);
    }
    localStream?.dispose();
    localStream = null;
    isCallActive = false;
    selectedTarget = null;
    notifyListeners();
  }

  void endCall(String peerCode) {
    _closePeer(peerCode);
    isCallActive = peerConnections.isNotEmpty;
    selectedTarget = null;
    notifyListeners();
  }

  bool get isMuted {
    if (localStream == null) return true;
    return !(localStream!.getAudioTracks().first.enabled);
  }

  void muteMic() {
    if (localStream == null) return;
    for (final t in localStream!.getAudioTracks()) {
      t.enabled = !t.enabled;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    endAllCalls();
    userPresenceController.close();
    try {
      socket.disconnect();
    } catch (_) {}
    super.dispose();
  }
}