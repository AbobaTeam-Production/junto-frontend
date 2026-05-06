// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get onboardingSkipButton => 'Пропустить';

  @override
  String get onboardingNextButton => 'Дальше';

  @override
  String get onboardingStartButton => 'Начать';

  @override
  String get onboardingPage1Title => 'Кино — это\nповод встретиться.';

  @override
  String get onboardingPage1Subtitle =>
      'Junto собирает друзей в одной комнате — синхронный плеер, голос без эха, реакции в реальном времени.';

  @override
  String get onboardingPage2Title => 'Файл, торрент\nили Rutube.';

  @override
  String get onboardingPage2Subtitle =>
      'Загружайте локальный файл, добавляйте магнет-ссылку или вставляйте URL — Junto синхронизирует поток.';

  @override
  String get onboardingPage3Title => 'Голос без\nэха и наушников.';

  @override
  String get onboardingPage3Subtitle =>
      'Голосовой чат с подавлением эхо: можно говорить через колонки, никто не услышит свой голос обратно.';

  @override
  String get loginEmptyFieldsError => 'Заполните все поля';

  @override
  String get loginErrorDefault => 'Ошибка входа';

  @override
  String get loginUsernameHint => 'Имя пользователя';

  @override
  String get loginPasswordHint => 'Пароль';

  @override
  String get loginButton => 'Войти';

  @override
  String get loginNoAccount => 'Нет аккаунта?';

  @override
  String get loginCreateAccount => 'Создать';

  @override
  String get loginSubtitle => 'Смотрите вместе';

  @override
  String get loginDivider => 'или';

  @override
  String get loginGuestButton => 'Войти как гость';

  @override
  String get loginGuestError => 'Не удалось войти как гость';

  @override
  String get registerTitle => 'Создать аккаунт';

  @override
  String get registerSubtitle => 'Присоединяйтесь к совместным просмотрам';

  @override
  String get registerUsernameHint => 'Имя пользователя';

  @override
  String get registerEmailHint => 'Email';

  @override
  String get registerPasswordHint => 'Пароль';

  @override
  String get registerConfirmHint => 'Повторите пароль';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get registerEmptyFieldsError => 'Заполните все поля';

  @override
  String get registerPasswordMismatch => 'Пароли не совпадают';

  @override
  String get registerErrorDefault => 'Ошибка регистрации';

  @override
  String get registerHasAccount => 'Уже есть аккаунт?';

  @override
  String get registerLoginLink => 'Войти';

  @override
  String homeGreetingPrefix(String name) {
    return 'Привет, $name';
  }

  @override
  String get homeGreetingQuestion => 'Что смотрим?';

  @override
  String get homeCreateRoomLabel => 'Новый сеанс';

  @override
  String get homeCreateRoomTitle => 'Создать комнату';

  @override
  String get homeCreateRoomDesc =>
      'Загрузите фильм или вставьте ссылку. Друзья присоединяются по коду.';

  @override
  String get homeCreateRoomButton => 'Начать';

  @override
  String get homeJoinCodeLabel => 'Войти по коду';

  @override
  String get homeJoinCodeHint => '6 символов · от друга';

  @override
  String get homeLiveRoomsLabel => 'Сейчас смотрят друзья';

  @override
  String get homeLiveRoomsEmpty => 'Тихо';

  @override
  String get homeLiveRoomsEmptyDesc =>
      'Никто не смотрит сейчас.\nСоздай комнату — позови друзей.';

  @override
  String get homeRoomLabel => 'Комната';

  @override
  String get homeRoomMembers => 'в комнате';

  @override
  String get roomsTitle => 'Комнаты';

  @override
  String get roomsCountLabel => 'комнат';

  @override
  String get roomsFilterAll => 'Все';

  @override
  String get roomsFilterActive => 'Идут';

  @override
  String get roomsFilterMine => 'Мои';

  @override
  String get roomsFilterArchive => 'Архив';

  @override
  String get roomsNewButton => 'Новая';

  @override
  String get roomsEmptyState => 'Нет активных комнат';

  @override
  String get roomsEmptyDesc =>
      'Создайте комнату или присоединитесь\nпо коду приглашения';

  @override
  String get roomsDeleteTitle => 'Удалить комнату?';

  @override
  String roomsDeleteMessage(String code) {
    return '$code будет закрыта.';
  }

  @override
  String get roomsDeleteCancel => 'Отмена';

  @override
  String get roomsDeleteConfirm => 'Удалить';

  @override
  String roomsDeleteError(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get roomsLoadError => 'Не удалось загрузить комнаты';

  @override
  String get roomsLoadRetry => 'Повторить';

  @override
  String get roomsOnline => 'в эфире';

  @override
  String get roomLiveLabel => 'LIVE';

  @override
  String get roomOnlineCount => 'в эфире';

  @override
  String get roomCodeCopied => 'Код скопирован';

  @override
  String get roomLeaveTitle => 'Покинуть комнату?';

  @override
  String get roomLeaveMessage => 'Вы уверены, что хотите выйти из комнаты?';

  @override
  String get roomLeaveCancel => 'Остаться';

  @override
  String get roomLeaveConfirm => 'Выйти';

  @override
  String get roomPresenceLabel => 'В комнате';

  @override
  String get roomEmptySeats => 'Ещё никого нет — пригласи по коду.';

  @override
  String roomVideoProcessing(int progress) {
    return 'Обработка видео: $progress%';
  }

  @override
  String get roomVideoWaiting => 'Ожидание контента...';

  @override
  String get roomTabChat => 'Чат';

  @override
  String get roomTabParticipants => 'Участники';

  @override
  String get roomTabQueue => 'Очередь';

  @override
  String get roomMicLabel => 'Голос. чат';

  @override
  String get roomMicActiveLabel => 'Микрофон';

  @override
  String get roomMicEnableLabel => 'Вкл. микрофон';

  @override
  String get roomSpeakerLabel => 'Динамик';

  @override
  String get roomSpeakerAltLabel => 'Разговорный';

  @override
  String get roomReactionsLabel => 'Реакция';

  @override
  String get roomReactionsTitle => 'Реакции';

  @override
  String get chatPlaceholder => 'Сообщение...';

  @override
  String get chatEmpty => 'Пока нет сообщений';

  @override
  String get chatYouLabel => 'Вы';

  @override
  String get participantHostLabel => 'Хост';

  @override
  String get participantHostRole => 'Управляет плеером';

  @override
  String get participantViewerRole => 'Зритель';

  @override
  String get participantLoadError => 'Не удалось загрузить';

  @override
  String get queueAddButton => 'Добавить в очередь';

  @override
  String get queueEmpty => 'Очередь пуста';

  @override
  String queueProcessing(int progress) {
    return 'Обработка: $progress%';
  }

  @override
  String get queueError => 'Ошибка';

  @override
  String get queueLoadError => 'Не удалось загрузить';

  @override
  String get profileTitle => 'Я';

  @override
  String get profileLabel => 'Профиль';

  @override
  String get profileGuestLabel => 'Гость';

  @override
  String get profileGuestHandle => '— · войдите';

  @override
  String get profileSettingsTitle => 'Настройки';

  @override
  String get profileNotifications => 'Уведомления';

  @override
  String get profileNotificationsOn => 'Вкл';

  @override
  String get profileNotificationsOff => 'Выкл';

  @override
  String get profileLanguage => 'Язык';

  @override
  String get profileLanguageRu => 'Русский';

  @override
  String get profileLanguageEn => 'English';

  @override
  String get profileMicrophone => 'Микрофон';

  @override
  String get profileMicrophoneDefault => 'По умолч.';

  @override
  String get profileAboutTitle => 'О приложении';

  @override
  String get profileVersion => 'Версия';

  @override
  String get profileLicenses => 'Лицензии';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get profileLogoutConfirmTitle => 'Выход';

  @override
  String get profileLogoutConfirmMessage => 'Вы уверены, что хотите выйти?';

  @override
  String get profileLogoutCancel => 'Отмена';

  @override
  String get profileLogoutConfirm => 'Выйти';

  @override
  String get profileLoginButton => 'Войти в аккаунт';

  @override
  String get profileRegisterButton => 'Зарегистрироваться';

  @override
  String get profileSessionsLabel => 'сеансов';

  @override
  String get profileHoursLabel => 'часов';

  @override
  String get profileFriendsLabel => 'друзей';

  @override
  String get profileStatsPlaceholder => '—';

  @override
  String get editProfileTitle => 'Редактировать профиль';

  @override
  String get editProfileUsername => 'Имя пользователя';

  @override
  String get editProfileEmail => 'Email';

  @override
  String get editProfileSaveButton => 'Сохранить';

  @override
  String get editProfileEmptyError => 'Имя пользователя не может быть пустым';

  @override
  String editProfileError(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get createRoomTitle => 'Создать комнату';

  @override
  String get createRoomSourceLabel => 'Источник контента';

  @override
  String get sourceFile => 'Файл';

  @override
  String get sourceTorrent => 'Торрент';

  @override
  String get sourceRutube => 'Rutube';

  @override
  String get createRoomSearchHint => 'Название фильма или сериала';

  @override
  String get createRoomMagnetHint => 'или вставьте magnet-ссылку';

  @override
  String get createRoomRutubeHint => 'Ссылка на Rutube';

  @override
  String get createRoomButton => 'Создать';

  @override
  String get createRoomMagnetButton => 'Создать по ссылке';

  @override
  String get createRoomFileError => 'Выберите файл';

  @override
  String get createRoomUrlError => 'Вставьте ссылку';

  @override
  String createRoomSearchError(String message) {
    return 'Ошибка поиска: $message';
  }

  @override
  String createRoomError(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get createRoomMagnetError => 'У результата нет magnet-ссылки';

  @override
  String get createRoomFileReadError => 'Не удалось прочитать файл';

  @override
  String get createRoomUploadHint => 'Нажмите для выбора файла';

  @override
  String get createRoomFileFormats => 'MP4, MKV, AVI, MOV — до 10 ГБ';

  @override
  String get joinRoomTitle => 'Присоединиться';

  @override
  String get joinRoomHint => 'Введите 6-значный код приглашения';

  @override
  String get joinRoomCodeError => 'Код должен содержать 6 символов';

  @override
  String get joinRoomButton => 'Войти в комнату';

  @override
  String get joinRoomError => 'Не удалось присоединиться к комнате';

  @override
  String get addMediaTitle => 'Добавить в очередь';

  @override
  String get addMediaSourceLabel => 'Источник';

  @override
  String get addMediaSearchHint => 'Название фильма или сериала';

  @override
  String get addMediaMagnetHint => 'или вставьте magnet-ссылку';

  @override
  String get addMediaRutubeHint => 'Ссылка на Rutube';

  @override
  String get addMediaButton => 'Добавить';

  @override
  String get addMediaMagnetButton => 'Добавить по ссылке';

  @override
  String get addMediaFileError => 'Выберите файл';

  @override
  String get addMediaUrlError => 'Вставьте ссылку';

  @override
  String addMediaSearchError(String message) {
    return 'Ошибка поиска: $message';
  }

  @override
  String addMediaError(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get addMediaMagnetError => 'У результата нет magnet-ссылки';

  @override
  String get addMediaFileReadError => 'Не удалось прочитать файл';

  @override
  String get addMediaUploadHint => 'Нажмите для выбора файла';

  @override
  String get navHome => 'Сейчас';

  @override
  String get navRooms => 'Комнаты';

  @override
  String get navProfile => 'Я';

  @override
  String get friendsScreenTitle => 'Друзья';

  @override
  String get friendsTabFriends => 'Друзья';

  @override
  String get friendsTabRequests => 'Заявки';

  @override
  String friendsTabRequestsBadge(int count) {
    return 'Заявки ($count)';
  }

  @override
  String get friendsTabSearch => 'Найти';

  @override
  String get friendsEmpty => 'Пока никого';

  @override
  String get friendsEmptyDesc => 'Найдите друга по имени и отправьте заявку.';

  @override
  String get friendsRequestsEmpty => 'Заявок нет';

  @override
  String get friendsSearchHint => 'Имя пользователя';

  @override
  String get friendsSearchEmpty => 'Никто не нашёлся';

  @override
  String get friendsActionAdd => 'Добавить';

  @override
  String get friendsActionPending => 'Заявка отправлена';

  @override
  String get friendsActionAccept => 'Принять';

  @override
  String get friendsActionDecline => 'Отклонить';

  @override
  String get friendsActionRemove => 'Удалить';

  @override
  String get friendsRemoveConfirm => 'Удалить из друзей?';
}
