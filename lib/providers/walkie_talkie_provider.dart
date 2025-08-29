import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:one_one/services/socket_service.dart';

class WalkieTalkieProvider extends ChangeNotifier {
  late IO.Socket socket;
  final SocketHandler _socketHandler = SocketHandler();

  String userName = '';
  String uniqueCode = '';
  String connectedUserName = '';
  String connectedUserCode = '';
  List<Map<String, String>> connectedUsers = [];
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;
  List<Map<String, String>> messages = [];
  bool isCallActive = false;
  bool isConnected = false;

  Future<void> saveToLocalStorage(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(value);
    await prefs.setString(key, value);
  }

  Future<String?> readFromLocalStorage(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(key);
  }

  WalkieTalkieProvider() {
    initialize();
  }

  Future<void> initialize() async {
    // New method for foreground service
    print('Initializing foreground service');
    await _initializeSocket();
  }

  // New method for foreground service initialization

  // Modified _initializeSocket method
  Future<void> _initializeSocket() async {
    try {
      _socketHandler.initSocket();
      socket = _socketHandler.socket!;

      socket.onConnect((_) {
        isConnected = true;
        debugPrint('Socket connected');
      });
      socket.onDisconnect((_) {
        isConnected = false;
        debugPrint('Socket disconnected');
      });

      setupSocketListeners();
    } catch (e) {
      debugPrint('Socket initialization error: $e');
    }
  }

  void setupSocketListeners() {
    socket.on('your-unique-code', (code) {
      uniqueCode = code;
      saveToLocalStorage("uniqueCode", code);
      notifyListeners();
    });

    socket.on('user-connected', (data) {
      if (data['uniqueCode'] != uniqueCode) {
        connectedUsers.add({
          'name': data['name'],
          'code': data['uniqueCode'],
        });
        notifyListeners();
      }
    });

    socket.on('connected-users', (data) {
      connectedUsers.clear();
      connectedUsers.addAll(
        List<Map<String, String>>.from(
          (data as List).map((user) => {
                'name': user['name'] as String,
                'code': user['uniqueCode'] as String,
              }),
        ),
      );
      notifyListeners();
    });

    socket.on('receive-message', (data) {
      if (data['receiver'] == uniqueCode) {
        messages.add({
          'text': data['text'],
          'sender': data['sender'],
        });
        notifyListeners();
      }
    });

    socket.on('user-disconnected', (data) {
      connectedUsers.removeWhere((user) => user['code'] == data['uniqueCode']);
      notifyListeners();
    });

    setupWebRTCListeners();
  }

  void setupWebRTCListeners() {
    socket.on('offer', (data) async {
      print('Offer received:: $data');
      if (data['receiver'] == uniqueCode) {
        await autoAcceptCall(data);
      }
    });

    socket.on('answer', (data) async {
      if (data['receiver'] == uniqueCode) {
        await handleAnswer(data);
      }
    });

    socket.on('ice-candidate', (data) async {
      if (data['receiver'] == uniqueCode) {
        await handleIceCandidate(data);
      }
    });
  }

  Future<void> initializePeerConnection() async {
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
        'receiver': connectedUserCode,
      });
    };

    peerConnection!.onTrack = (event) {
      remoteStream = event.streams[0];
      notifyListeners();
    };

    localStream = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': false});

    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });
  }

  Future<void> startCall(code) async {
    await initializePeerConnection();
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    connectedUserCode = code;
    socket.emit('offer', {
      'sdp': offer.sdp,
      'sender': await readFromLocalStorage("uniqueCode") ?? uniqueCode,
      'receiver': connectedUserCode,
    });

    isCallActive = true;
    notifyListeners();
  }

  Future<void>  autoAcceptCall(Map data) async {
    await initializePeerConnection();
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(data['sdp'], 'offer'),
    );

    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    socket.emit('answer', {
      'sdp': answer.sdp,
      'sender': uniqueCode,
      'receiver': data['sender'],
    });

    connectedUserCode = data['sender'];
    isCallActive = true;
    notifyListeners();
  }

  Future<void> handleAnswer(Map data) async {
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(data['sdp'], 'answer'),
    );
  }

  Future<void> handleIceCandidate(Map data) async {
    await peerConnection?.addCandidate(
      RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      ),
    );
  }

  void connectToUser(String code, String name) {
    connectedUserCode = code;
    connectedUserName = name;
    notifyListeners();
  }

  void disposeResources() {
    localStream?.dispose();
    remoteStream?.dispose();
    peerConnection?.dispose();
    isCallActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeResources();
    FlutterForegroundTask.stopService(); // Stop foreground service
    socket.disconnect();
    super.dispose();
  }
}
