class ApiEndpoints {
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String guest = '/auth/guest/';
  static const String refresh = '/auth/refresh/';
  static const String profile = '/auth/profile/';

  static const String roomCreate = '/rooms/create/';
  static const String roomJoin = '/rooms/join/';
  static const String rooms = '/rooms/';
  static String roomDetail(String id) => '/rooms/$id/';

  static const String mediaUpload = '/media/upload/';
  static const String mediaYoutube = '/media/youtube/';
  static const String mediaTorrent = '/media/torrent/';
  static String mediaStatus(String id) => '/media/$id/status/';
}
