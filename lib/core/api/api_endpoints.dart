class ApiEndpoints {
  static const String serverTime = '/time/';

  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String guest = '/auth/guest/';
  static const String refresh = '/auth/refresh/';
  static const String profile = '/auth/profile/';

  static const String roomCreate = '/rooms/create/';
  static const String roomJoin = '/rooms/join/';
  static const String rooms = '/rooms/';
  static String roomDetail(String id) => '/rooms/$id/';
  static String roomLivekitToken(String id) => '/rooms/$id/livekit-token/';

  static const String mediaUpload = '/media/upload/';
  static const String mediaYoutube = '/media/youtube/';
  static const String mediaTorrent = '/media/torrent/';
  static const String torrentSearch = '/media/torrent/search/';
  static String mediaStatus(String id) => '/media/$id/status/';
  static String mediaTranscode(String id) => '/media/$id/transcode/';

  // Social — friends + user search
  static const String friends = '/friends/';
  static const String friendRequests = '/friends/requests/';
  static const String friendRequestSend = '/friends/request/';
  static String friendAccept(int id) => '/friends/$id/accept/';
  static String friendDelete(int id) => '/friends/$id/';
  static const String userSearch = '/users/search/';
}
