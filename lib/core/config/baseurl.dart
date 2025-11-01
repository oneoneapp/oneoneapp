const String baseUrlRemote = "https://api.oneoneapp.in/";
const String baseUrlLocal = "http://192.168.220.13:5050/";

// Use --dart-define=USE_REMOTE=true to select the remote URL at compile time.
// Example: flutter run --dart-define=USE_REMOTE=true
const bool _useRemote = bool.fromEnvironment('USE_REMOTE', defaultValue: false);
const String baseUrl = _useRemote ? baseUrlRemote : baseUrlLocal;