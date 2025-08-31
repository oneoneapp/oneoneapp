import 'package:talker/talker.dart';

final Talker logger = Talker(
  settings: TalkerSettings(
    colors: {
      "info": AnsiPen()..cyan(),
    }
  )
);