import 'dart:async';
import 'package:flutter/material.dart';
import 'package:one_one/core/config/baseurl.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalkieTalkieProvider extends ChangeNotifier {
  late Socket socket;
  late StreamController onConnectedUser;

  String uniqueCode = '';

  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;

  bool isCallActive = false;
  bool isConnected = false;

  Future<void> initialize() async {
    onConnectedUser = StreamController.broadcast();
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
      onConnectedUser.add(data);
      notifyListeners();
    });

    socket.on('user-disconnected', (data) {
      logger.debug('User disconnected: $data');
      onConnectedUser.add(data);
      notifyListeners();
    });

    socket.on('friends-list', (data) {
      logger.debug('Friends list received: $data');
      notifyListeners();
    });
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
    socket.disconnect();
    super.dispose();
  }
}
