class ActiveSpeakerEvent {
  final String socketId;
  final bool speaking;
  final DateTime timestamp;

  ActiveSpeakerEvent({
    required this.socketId,
    required this.speaking
  }) : timestamp = DateTime.now();
}