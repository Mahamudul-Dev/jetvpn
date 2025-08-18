class AppConfig {
  static const String appName = 'JetVPN';
  static const String appVersion = '1.0.0';
  static const String vpnMethodChannel = 'com.codejet.jetvpn/channel';
  static const String baseUrl = 'https://jetvpn.codejet.dev';
  static const String storagePath = '$baseUrl/storage/';
  static const String apiPath = '$baseUrl/api/v1';
  static const String serversPath = '$apiPath/servers';
  static const int serverResultLimit = 30;
}