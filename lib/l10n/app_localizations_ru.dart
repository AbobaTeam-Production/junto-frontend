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
  String get profileTabAccount => 'Аккаунт';

  @override
  String get profileTabAudioVideo => 'Звук и микрофон';

  @override
  String get profileTabSessions => 'Сеансы';

  @override
  String get profileNickname => 'Никнейм';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileEdit => 'Изменить';

  @override
  String get profileChange => 'Сменить';

  @override
  String get profileOpen => 'Открыть →';

  @override
  String get profilePushOn => 'Push включены';

  @override
  String get profilePushOff => 'Push выключены';

  @override
  String get profilePushDesc => 'Друзья, приглашения, реакции';

  @override
  String get profileAudioVideoGroup => 'Звук · видео · язык';

  @override
  String get profileSystemDevice => 'Системное устройство';

  @override
  String get profileSessionsGroup => 'Последние сеансы';

  @override
  String get profileSessionsHistory => 'История просмотров';

  @override
  String get profileSessionsHistoryDesc => 'Все ваши совместные просмотры';

  @override
  String get profileSessionsEmpty => 'Пока нет сеансов';

  @override
  String get profileSessionsEmptyDesc =>
      'После первого фильма здесь появится список';

  @override
  String get profileLicensesDesc => 'Open-source компоненты';

  @override
  String get profileGuestMode => 'Вы в гостевом режиме';

  @override
  String get profileGuestModeDesc =>
      'Войдите, чтобы синхронизировать настройки и сохранить друзей.';

  @override
  String get profileFcmPermissionDenied =>
      'Разрешение не выдано — проверьте настройки сайта/приложения.';

  @override
  String get profileFcmUnsupported =>
      'Платформа не поддерживает push-уведомления.';

  @override
  String profileFcmBackendError(String error) {
    return 'Сервер не принял токен: $error';
  }

  @override
  String profileFcmInitError(String error) {
    return 'Не удалось инициализировать FCM: $error';
  }

  @override
  String get profileEditButton => 'Изменить';

  @override
  String get loginSubmit => 'Войти';

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
  String get sessionsHistoryTitle => 'Последние сеансы';

  @override
  String get sessionsHistoryEmpty => 'Пока ни одного сеанса';

  @override
  String get sessionsHistoryEnter => 'Зайти';

  @override
  String sessionsHistoryRoomTitle(String code) {
    return 'Комната $code';
  }

  @override
  String sessionsHistoryDurationHours(int h, int m) {
    return '$h ч $m мин';
  }

  @override
  String sessionsHistoryDurationMinutes(int m) {
    return '$m мин';
  }

  @override
  String sessionsHistoryDurationSeconds(int s) {
    return '$s с';
  }

  @override
  String get sessionsHistoryAgoJustNow => 'только что';

  @override
  String sessionsHistoryAgoMinutes(int n) {
    return '$n мин назад';
  }

  @override
  String sessionsHistoryAgoHours(int n) {
    return '$n ч назад';
  }

  @override
  String sessionsHistoryAgoDays(int n) {
    return '$n дн назад';
  }

  @override
  String get sessionsHistoryError => 'Не удалось загрузить';

  @override
  String get navRecs => 'Подборки';

  @override
  String recsFeedDateLabel(String date, String time) {
    return '$date · $time';
  }

  @override
  String get recsFeedTitle => 'Что посмотреть';

  @override
  String get recsFeedTitleAccent => 'вечером?';

  @override
  String get recsFeedFreeNow => 'Сейчас в сети';

  @override
  String recsFeedFreeCount(int n) {
    return '$n в сети';
  }

  @override
  String get recsFeedTopMatch => 'Топ-совпадение';

  @override
  String recsFeedFriendWantsToWatch(String name) {
    return '$name хочет посмотреть';
  }

  @override
  String get recsFeedMoodsLabel => 'По настроению';

  @override
  String get recsFeedTopKpLabel => 'Высокий рейтинг КиноПоиска';

  @override
  String get recsFeedTrendingLabel => 'Горячее этой недели';

  @override
  String get recsSearchTitle => 'Поиск';

  @override
  String get recsSearchPlaceholder => 'Название фильма…';

  @override
  String get recsSearchHint => 'Начните печатать — найдём в каталоге и в TMDb';

  @override
  String get recsSearchNoResults => 'Ничего не нашлось';

  @override
  String recsFeedMatchPercent(int n) {
    return '$n% совпадение';
  }

  @override
  String recsFeedFriendsLikeIt(int n) {
    return 'понравится $n';
  }

  @override
  String get recsFeedInvite => 'Позвать';

  @override
  String get recsFeedEmpty => 'Пока пусто. Добавьте подборки в админке.';

  @override
  String recsFeedMoodMoviesCount(int n) {
    return '$n фильмов';
  }

  @override
  String get recsPresenceFree => 'в сети';

  @override
  String get recsPresenceBusy => 'в комнате';

  @override
  String get recsPresenceIdle => 'не в сети';

  @override
  String get recsMatchHeader => 'совпадение вкусов';

  @override
  String recsMatchPairLabel(String name) {
    return 'Ты и $name';
  }

  @override
  String recsMatchOverlapStat(int percent, int count) {
    return '$percent% общих вкусов · $count совпадений';
  }

  @override
  String get recsMatchSharedTags => 'Любите оба';

  @override
  String get recsMatchListLabel => 'Рекомендуем вдвоём';

  @override
  String get recsMatchInsufficient =>
      'Соберите больше истории — пересечения появятся, когда у каждого будет 3+ просмотра.';

  @override
  String recsMatchCta(String name) {
    return 'Создать комнату с $name';
  }

  @override
  String get recsMoodHeader => 'Настроение';

  @override
  String get recsMoodTitle => 'Сегодня хочется';

  @override
  String recsMoodTitleAccent(String mood) {
    return '$mood.';
  }

  @override
  String get recsMoodEmpty => 'В этой подборке пока пусто';

  @override
  String recsTitleMatchHeader(int percent) {
    return '$percent% совпадение';
  }

  @override
  String get recsTitleWhy => 'Почему рекомендуем';

  @override
  String get recsTitleWillLike => 'Понравится';

  @override
  String recsTitleCta(String names) {
    return 'Позвать $names';
  }

  @override
  String get recsTitleCtaJoinSelf => 'Создать комнату';

  @override
  String get recsTitleIntentAdd => 'Хочу посмотреть';

  @override
  String get recsTitleIntentRemove => 'Передумал';

  @override
  String get recsTitleWatchTrailer => 'Трейлер';

  @override
  String get tasteOnboardingTitle => 'Что вам ближе?';

  @override
  String get tasteOnboardingSubtitle =>
      'Отметьте 3-5 фильмов — мы подберём похожие и поймём, кого из друзей звать.';

  @override
  String get tasteOnboardingCta => 'Готово';

  @override
  String get tasteOnboardingSkip => 'Пропустить';

  @override
  String tasteOnboardingHint(int n) {
    return 'Выбрано: $n';
  }

  @override
  String get onboardingTagTogether => '01 — Together';

  @override
  String get onboardingTagOneRoom => '02 — В одной комнате';

  @override
  String get onboardingTagAnySource => '03 — Любой источник';

  @override
  String get onboardingSourceTagsLine => 'FILES · TORRENT · RUTUBE · VOICE';

  @override
  String get onboardingScreenSubtitle => '«Мы в одной комнате.»';

  @override
  String get onboardingSourceFile => 'Файл';

  @override
  String get onboardingSourceFileExt => '.mp4 · .mkv\n.webm · .mov';

  @override
  String get onboardingSourceFileBadge => 'Самое популярное';

  @override
  String get onboardingSourceTorrent => 'Торрент';

  @override
  String get onboardingSourceTorrentExt => '.torrent / magnet';

  @override
  String get onboardingSourceRutube => 'Rutube';

  @override
  String get onboardingSourceRutubeExt => 'rutube.ru/...';

  @override
  String get onboardingSourceStream => 'Стрим';

  @override
  String get onboardingSourceStreamExt => 'HLS / m3u8';

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

  @override
  String get billingPlansTitle => 'Junto Pro';

  @override
  String get billingPlansSubtitle =>
      'Соберите полный зал и смотрите без рекламы';

  @override
  String get billingPeriodMonthly => 'В месяц';

  @override
  String get billingPeriodYearly => 'В год';

  @override
  String get billingPriceFree => 'Бесплатно';

  @override
  String billingPriceMonthly(String amount) {
    return '$amount ₽/мес';
  }

  @override
  String billingPriceYearly(String amount) {
    return '$amount ₽/год';
  }

  @override
  String get billingCtaSubscribe => 'Оформить';

  @override
  String get billingCtaCurrent => 'Активен';

  @override
  String get billingCheckoutTitle => 'Оплата подписки';

  @override
  String get billingCheckoutCardNumber => 'Номер карты';

  @override
  String get billingCheckoutCardExpiry => 'MM / ГГ';

  @override
  String get billingCheckoutCardCvc => 'CVC';

  @override
  String billingCheckoutPayCta(String amount) {
    return 'Оплатить $amount ₽';
  }

  @override
  String get billingCheckoutDisclaimer =>
      'Демо-форма. Реальная оплата не произойдёт.';

  @override
  String get billingSuccessTitle => 'Готово';

  @override
  String billingSuccessBody(String plan) {
    return 'Добро пожаловать в $plan';
  }

  @override
  String get billingSuccessCta => 'Открыть Junto';

  @override
  String get billingManageTitle => 'Подписка';

  @override
  String billingManageActive(String date) {
    return 'Активна до $date';
  }

  @override
  String get billingManageCancelCta => 'Отменить подписку';

  @override
  String get billingManageCancelConfirm => 'Вернуть бесплатный тариф?';

  @override
  String get billingManageCancelled => 'Подписка отменена';

  @override
  String get paywallRoomSizeTitle => 'Соберите больше друзей';

  @override
  String get paywallRoomSizeBody =>
      'С Junto Pro в одной комнате до 10 человек, с Cinema — до 25.';

  @override
  String get paywallRoomSizeCta => 'Узнать про Pro';

  @override
  String get paywallHistoryTitle => 'История за всё время';

  @override
  String get paywallHistoryBody =>
      'Free хранит последние 30 дней. С Pro — навсегда.';

  @override
  String get paywallAdsTitle => 'Без рекламы';

  @override
  String get paywallAdsBody =>
      'Junto Pro убирает партнёрские подборки из ленты.';

  @override
  String get profileBillingProCta => 'Junto Pro';

  @override
  String get profileBillingProCtaSubtitle => 'Снять лимиты и убрать рекламу';

  @override
  String get profileBillingProBadge => 'PRO';

  @override
  String get profileBillingManage => 'Подписка';
}
