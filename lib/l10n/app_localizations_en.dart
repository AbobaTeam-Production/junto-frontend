// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingSkipButton => 'Skip';

  @override
  String get onboardingNextButton => 'Next';

  @override
  String get onboardingStartButton => 'Get started';

  @override
  String get onboardingPage1Title => 'Movies are\nbetter together.';

  @override
  String get onboardingPage1Subtitle =>
      'Junto puts friends in one room — synced player, echo-free voice, real-time reactions.';

  @override
  String get onboardingPage2Title => 'File, torrent\nor Rutube.';

  @override
  String get onboardingPage2Subtitle =>
      'Upload a local file, paste a magnet link or a URL — Junto syncs the stream for everyone.';

  @override
  String get onboardingPage3Title => 'Voice without\necho or headphones.';

  @override
  String get onboardingPage3Subtitle =>
      'Voice chat with echo cancellation: speak through speakers, no one hears their own voice back.';

  @override
  String get loginEmptyFieldsError => 'Fill in all fields';

  @override
  String get loginErrorDefault => 'Sign-in failed';

  @override
  String get loginUsernameHint => 'Username';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginNoAccount => 'No account?';

  @override
  String get loginCreateAccount => 'Create';

  @override
  String get loginSubtitle => 'Watch together';

  @override
  String get loginDivider => 'or';

  @override
  String get loginGuestButton => 'Continue as guest';

  @override
  String get loginGuestError => 'Couldn\'t sign in as guest';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Join shared watch parties';

  @override
  String get registerUsernameHint => 'Username';

  @override
  String get registerEmailHint => 'Email';

  @override
  String get registerPasswordHint => 'Password';

  @override
  String get registerConfirmHint => 'Repeat password';

  @override
  String get registerButton => 'Sign up';

  @override
  String get registerEmptyFieldsError => 'Fill in all fields';

  @override
  String get registerPasswordMismatch => 'Passwords don\'t match';

  @override
  String get registerErrorDefault => 'Sign-up failed';

  @override
  String get registerHasAccount => 'Already have an account?';

  @override
  String get registerLoginLink => 'Sign in';

  @override
  String homeGreetingPrefix(String name) {
    return 'Hi, $name';
  }

  @override
  String get homeGreetingQuestion => 'What are we watching?';

  @override
  String get homeCreateRoomLabel => 'New session';

  @override
  String get homeCreateRoomTitle => 'Create room';

  @override
  String get homeCreateRoomDesc =>
      'Upload a movie or paste a link. Friends join with the code.';

  @override
  String get homeCreateRoomButton => 'Start';

  @override
  String get homeJoinCodeLabel => 'Join by code';

  @override
  String get homeJoinCodeHint => '6 chars · from a friend';

  @override
  String get homeLiveRoomsLabel => 'Friends are watching now';

  @override
  String get homeLiveRoomsEmpty => 'Quiet';

  @override
  String get homeLiveRoomsEmptyDesc =>
      'Nobody\'s watching right now.\nCreate a room — invite friends.';

  @override
  String get homeRoomLabel => 'Room';

  @override
  String get homeRoomMembers => 'in room';

  @override
  String get roomsTitle => 'Rooms';

  @override
  String get roomsCountLabel => 'rooms';

  @override
  String get roomsFilterAll => 'All';

  @override
  String get roomsFilterActive => 'Live';

  @override
  String get roomsFilterMine => 'Mine';

  @override
  String get roomsFilterArchive => 'Archive';

  @override
  String get roomsNewButton => 'New';

  @override
  String get roomsEmptyState => 'No active rooms';

  @override
  String get roomsEmptyDesc => 'Create a room or join\nwith an invite code';

  @override
  String get roomsDeleteTitle => 'Delete room?';

  @override
  String roomsDeleteMessage(String code) {
    return '$code will be closed.';
  }

  @override
  String get roomsDeleteCancel => 'Cancel';

  @override
  String get roomsDeleteConfirm => 'Delete';

  @override
  String roomsDeleteError(String message) {
    return 'Error: $message';
  }

  @override
  String get roomsLoadError => 'Couldn\'t load rooms';

  @override
  String get roomsLoadRetry => 'Retry';

  @override
  String get roomsOnline => 'live';

  @override
  String get roomLiveLabel => 'LIVE';

  @override
  String get roomOnlineCount => 'live';

  @override
  String get roomCodeCopied => 'Code copied';

  @override
  String get roomLeaveTitle => 'Leave room?';

  @override
  String get roomLeaveMessage => 'Are you sure you want to leave?';

  @override
  String get roomLeaveCancel => 'Stay';

  @override
  String get roomLeaveConfirm => 'Leave';

  @override
  String get roomPresenceLabel => 'In the room';

  @override
  String get roomEmptySeats => 'No one yet — invite by code.';

  @override
  String roomVideoProcessing(int progress) {
    return 'Processing video: $progress%';
  }

  @override
  String get roomVideoWaiting => 'Waiting for content...';

  @override
  String get roomTabChat => 'Chat';

  @override
  String get roomTabParticipants => 'Members';

  @override
  String get roomTabQueue => 'Queue';

  @override
  String get roomMicLabel => 'Voice chat';

  @override
  String get roomMicActiveLabel => 'Microphone';

  @override
  String get roomMicEnableLabel => 'Turn on mic';

  @override
  String get roomSpeakerLabel => 'Speaker';

  @override
  String get roomSpeakerAltLabel => 'Earpiece';

  @override
  String get roomReactionsLabel => 'React';

  @override
  String get roomReactionsTitle => 'Reactions';

  @override
  String get chatPlaceholder => 'Message...';

  @override
  String get chatEmpty => 'No messages yet';

  @override
  String get chatYouLabel => 'You';

  @override
  String get participantHostLabel => 'Host';

  @override
  String get participantHostRole => 'Controls the player';

  @override
  String get participantViewerRole => 'Viewer';

  @override
  String get participantLoadError => 'Couldn\'t load';

  @override
  String get queueAddButton => 'Add to queue';

  @override
  String get queueEmpty => 'Queue is empty';

  @override
  String queueProcessing(int progress) {
    return 'Processing: $progress%';
  }

  @override
  String get queueError => 'Error';

  @override
  String get queueLoadError => 'Couldn\'t load';

  @override
  String get profileTitle => 'Me';

  @override
  String get profileLabel => 'Profile';

  @override
  String get profileGuestLabel => 'Guest';

  @override
  String get profileGuestHandle => '— · sign in';

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileNotificationsOn => 'On';

  @override
  String get profileNotificationsOff => 'Off';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageRu => 'Русский';

  @override
  String get profileLanguageEn => 'English';

  @override
  String get profileMicrophone => 'Microphone';

  @override
  String get profileMicrophoneDefault => 'Default';

  @override
  String get profileAboutTitle => 'About';

  @override
  String get profileVersion => 'Version';

  @override
  String get profileLicenses => 'Licenses';

  @override
  String get profileLogout => 'Sign out';

  @override
  String get profileLogoutConfirmTitle => 'Sign out';

  @override
  String get profileLogoutConfirmMessage =>
      'Are you sure you want to sign out?';

  @override
  String get profileLogoutCancel => 'Cancel';

  @override
  String get profileLogoutConfirm => 'Sign out';

  @override
  String get profileLoginButton => 'Sign in';

  @override
  String get profileRegisterButton => 'Sign up';

  @override
  String get profileSessionsLabel => 'sessions';

  @override
  String get profileHoursLabel => 'hours';

  @override
  String get profileFriendsLabel => 'friends';

  @override
  String get profileStatsPlaceholder => '—';

  @override
  String get sessionsHistoryTitle => 'Recent sessions';

  @override
  String get sessionsHistoryEmpty => 'No sessions yet';

  @override
  String get sessionsHistoryEnter => 'Enter';

  @override
  String sessionsHistoryRoomTitle(String code) {
    return 'Room $code';
  }

  @override
  String sessionsHistoryDurationHours(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String sessionsHistoryDurationMinutes(int m) {
    return '${m}m';
  }

  @override
  String sessionsHistoryDurationSeconds(int s) {
    return '${s}s';
  }

  @override
  String get sessionsHistoryAgoJustNow => 'just now';

  @override
  String sessionsHistoryAgoMinutes(int n) {
    return '$n min ago';
  }

  @override
  String sessionsHistoryAgoHours(int n) {
    return '${n}h ago';
  }

  @override
  String sessionsHistoryAgoDays(int n) {
    return '${n}d ago';
  }

  @override
  String get sessionsHistoryError => 'Failed to load';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileUsername => 'Username';

  @override
  String get editProfileEmail => 'Email';

  @override
  String get editProfileSaveButton => 'Save';

  @override
  String get editProfileEmptyError => 'Username can\'t be empty';

  @override
  String editProfileError(String message) {
    return 'Error: $message';
  }

  @override
  String get createRoomTitle => 'Create room';

  @override
  String get createRoomSourceLabel => 'Content source';

  @override
  String get sourceFile => 'File';

  @override
  String get sourceTorrent => 'Torrent';

  @override
  String get sourceRutube => 'Rutube';

  @override
  String get createRoomSearchHint => 'Movie or show title';

  @override
  String get createRoomMagnetHint => 'or paste a magnet link';

  @override
  String get createRoomRutubeHint => 'Rutube URL';

  @override
  String get createRoomButton => 'Create';

  @override
  String get createRoomMagnetButton => 'Create from link';

  @override
  String get createRoomFileError => 'Pick a file';

  @override
  String get createRoomUrlError => 'Paste a URL';

  @override
  String createRoomSearchError(String message) {
    return 'Search error: $message';
  }

  @override
  String createRoomError(String message) {
    return 'Error: $message';
  }

  @override
  String get createRoomMagnetError => 'This result has no magnet link';

  @override
  String get createRoomFileReadError => 'Couldn\'t read the file';

  @override
  String get createRoomUploadHint => 'Tap to pick a file';

  @override
  String get createRoomFileFormats => 'MP4, MKV, AVI, MOV — up to 10 GB';

  @override
  String get joinRoomTitle => 'Join';

  @override
  String get joinRoomHint => 'Enter the 6-character invite code';

  @override
  String get joinRoomCodeError => 'Code must be 6 characters';

  @override
  String get joinRoomButton => 'Join room';

  @override
  String get joinRoomError => 'Couldn\'t join the room';

  @override
  String get addMediaTitle => 'Add to queue';

  @override
  String get addMediaSourceLabel => 'Source';

  @override
  String get addMediaSearchHint => 'Movie or show title';

  @override
  String get addMediaMagnetHint => 'or paste a magnet link';

  @override
  String get addMediaRutubeHint => 'Rutube URL';

  @override
  String get addMediaButton => 'Add';

  @override
  String get addMediaMagnetButton => 'Add from link';

  @override
  String get addMediaFileError => 'Pick a file';

  @override
  String get addMediaUrlError => 'Paste a URL';

  @override
  String addMediaSearchError(String message) {
    return 'Search error: $message';
  }

  @override
  String addMediaError(String message) {
    return 'Error: $message';
  }

  @override
  String get addMediaMagnetError => 'This result has no magnet link';

  @override
  String get addMediaFileReadError => 'Couldn\'t read the file';

  @override
  String get addMediaUploadHint => 'Tap to pick a file';

  @override
  String get navHome => 'Now';

  @override
  String get navRooms => 'Rooms';

  @override
  String get navProfile => 'Me';

  @override
  String get friendsScreenTitle => 'Friends';

  @override
  String get friendsTabFriends => 'Friends';

  @override
  String get friendsTabRequests => 'Requests';

  @override
  String friendsTabRequestsBadge(int count) {
    return 'Requests ($count)';
  }

  @override
  String get friendsTabSearch => 'Find';

  @override
  String get friendsEmpty => 'No one yet';

  @override
  String get friendsEmptyDesc => 'Search by username and send a request.';

  @override
  String get friendsRequestsEmpty => 'No requests';

  @override
  String get friendsSearchHint => 'Username';

  @override
  String get friendsSearchEmpty => 'No matches';

  @override
  String get friendsActionAdd => 'Add';

  @override
  String get friendsActionPending => 'Request sent';

  @override
  String get friendsActionAccept => 'Accept';

  @override
  String get friendsActionDecline => 'Decline';

  @override
  String get friendsActionRemove => 'Remove';

  @override
  String get friendsRemoveConfirm => 'Remove from friends?';
}
