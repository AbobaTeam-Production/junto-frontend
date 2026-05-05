import 'package:media_kit/media_kit.dart';

void ensureVideoPlayerInitialized() {
  // media_kit needs to initialize on Web too — even though no native libs
  // are loaded, the call wires its internal MediaKit.runtime so the Player
  // constructor doesn't deadlock waiting on HLS.ensureInitialized().
  MediaKit.ensureInitialized();
}
