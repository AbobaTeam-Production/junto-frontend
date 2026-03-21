import 'player_api.dart';
import 'player_web.dart' if (dart.library.io) 'player_native.dart';

UnifiedVideoPlayer createVideoPlayer() => createPlatformPlayer();
