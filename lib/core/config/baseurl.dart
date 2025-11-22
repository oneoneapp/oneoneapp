const String baseUrlRemote = "https://api.oneoneapp.in/";
const String baseUrlLocal = "http://192.168.220.13:5050/";

const bool _useRemote = bool.fromEnvironment('USE_REMOTE', defaultValue: true);
const String baseUrl = _useRemote ? baseUrlRemote : baseUrlLocal;