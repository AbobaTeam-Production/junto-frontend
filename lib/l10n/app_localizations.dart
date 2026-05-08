import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @onboardingSkipButton.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get onboardingSkipButton;

  /// No description provided for @onboardingNextButton.
  ///
  /// In ru, this message translates to:
  /// **'Дальше'**
  String get onboardingNextButton;

  /// No description provided for @onboardingStartButton.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get onboardingStartButton;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In ru, this message translates to:
  /// **'Кино — это\nповод встретиться.'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Junto собирает друзей в одной комнате — синхронный плеер, голос без эха, реакции в реальном времени.'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In ru, this message translates to:
  /// **'Файл, торрент\nили Rutube.'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Загружайте локальный файл, добавляйте магнет-ссылку или вставляйте URL — Junto синхронизирует поток.'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In ru, this message translates to:
  /// **'Голос без\nэха и наушников.'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Голосовой чат с подавлением эхо: можно говорить через колонки, никто не услышит свой голос обратно.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @loginEmptyFieldsError.
  ///
  /// In ru, this message translates to:
  /// **'Заполните все поля'**
  String get loginEmptyFieldsError;

  /// No description provided for @loginErrorDefault.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа'**
  String get loginErrorDefault;

  /// No description provided for @loginUsernameHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя'**
  String get loginUsernameHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get loginCreateAccount;

  /// No description provided for @loginSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Смотрите вместе'**
  String get loginSubtitle;

  /// No description provided for @loginDivider.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get loginDivider;

  /// No description provided for @loginGuestButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти как гость'**
  String get loginGuestButton;

  /// No description provided for @loginGuestError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти как гость'**
  String get loginGuestError;

  /// No description provided for @registerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Присоединяйтесь к совместным просмотрам'**
  String get registerSubtitle;

  /// No description provided for @registerUsernameHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя'**
  String get registerUsernameHint;

  /// No description provided for @registerEmailHint.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get registerEmailHint;

  /// No description provided for @registerPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get registerPasswordHint;

  /// No description provided for @registerConfirmHint.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get registerConfirmHint;

  /// No description provided for @registerButton.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerButton;

  /// No description provided for @registerEmptyFieldsError.
  ///
  /// In ru, this message translates to:
  /// **'Заполните все поля'**
  String get registerEmptyFieldsError;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get registerPasswordMismatch;

  /// No description provided for @registerErrorDefault.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка регистрации'**
  String get registerErrorDefault;

  /// No description provided for @registerHasAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт?'**
  String get registerHasAccount;

  /// No description provided for @registerLoginLink.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get registerLoginLink;

  /// No description provided for @homeGreetingPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Привет, {name}'**
  String homeGreetingPrefix(String name);

  /// No description provided for @homeGreetingQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Что смотрим?'**
  String get homeGreetingQuestion;

  /// No description provided for @homeCreateRoomLabel.
  ///
  /// In ru, this message translates to:
  /// **'Новый сеанс'**
  String get homeCreateRoomLabel;

  /// No description provided for @homeCreateRoomTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создать комнату'**
  String get homeCreateRoomTitle;

  /// No description provided for @homeCreateRoomDesc.
  ///
  /// In ru, this message translates to:
  /// **'Загрузите фильм или вставьте ссылку. Друзья присоединяются по коду.'**
  String get homeCreateRoomDesc;

  /// No description provided for @homeCreateRoomButton.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get homeCreateRoomButton;

  /// No description provided for @homeJoinCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Войти по коду'**
  String get homeJoinCodeLabel;

  /// No description provided for @homeJoinCodeHint.
  ///
  /// In ru, this message translates to:
  /// **'6 символов · от друга'**
  String get homeJoinCodeHint;

  /// No description provided for @homeLiveRoomsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас смотрят друзья'**
  String get homeLiveRoomsLabel;

  /// No description provided for @homeLiveRoomsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Тихо'**
  String get homeLiveRoomsEmpty;

  /// No description provided for @homeLiveRoomsEmptyDesc.
  ///
  /// In ru, this message translates to:
  /// **'Никто не смотрит сейчас.\nСоздай комнату — позови друзей.'**
  String get homeLiveRoomsEmptyDesc;

  /// No description provided for @homeRoomLabel.
  ///
  /// In ru, this message translates to:
  /// **'Комната'**
  String get homeRoomLabel;

  /// No description provided for @homeRoomMembers.
  ///
  /// In ru, this message translates to:
  /// **'в комнате'**
  String get homeRoomMembers;

  /// No description provided for @roomsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Комнаты'**
  String get roomsTitle;

  /// No description provided for @roomsCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'комнат'**
  String get roomsCountLabel;

  /// No description provided for @roomsFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get roomsFilterAll;

  /// No description provided for @roomsFilterActive.
  ///
  /// In ru, this message translates to:
  /// **'Идут'**
  String get roomsFilterActive;

  /// No description provided for @roomsFilterMine.
  ///
  /// In ru, this message translates to:
  /// **'Мои'**
  String get roomsFilterMine;

  /// No description provided for @roomsFilterArchive.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get roomsFilterArchive;

  /// No description provided for @roomsNewButton.
  ///
  /// In ru, this message translates to:
  /// **'Новая'**
  String get roomsNewButton;

  /// No description provided for @roomsEmptyState.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных комнат'**
  String get roomsEmptyState;

  /// No description provided for @roomsEmptyDesc.
  ///
  /// In ru, this message translates to:
  /// **'Создайте комнату или присоединитесь\nпо коду приглашения'**
  String get roomsEmptyDesc;

  /// No description provided for @roomsDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить комнату?'**
  String get roomsDeleteTitle;

  /// No description provided for @roomsDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'{code} будет закрыта.'**
  String roomsDeleteMessage(String code);

  /// No description provided for @roomsDeleteCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get roomsDeleteCancel;

  /// No description provided for @roomsDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get roomsDeleteConfirm;

  /// No description provided for @roomsDeleteError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {message}'**
  String roomsDeleteError(String message);

  /// No description provided for @roomsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить комнаты'**
  String get roomsLoadError;

  /// No description provided for @roomsLoadRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get roomsLoadRetry;

  /// No description provided for @roomsOnline.
  ///
  /// In ru, this message translates to:
  /// **'в эфире'**
  String get roomsOnline;

  /// No description provided for @roomLiveLabel.
  ///
  /// In ru, this message translates to:
  /// **'LIVE'**
  String get roomLiveLabel;

  /// No description provided for @roomOnlineCount.
  ///
  /// In ru, this message translates to:
  /// **'в эфире'**
  String get roomOnlineCount;

  /// No description provided for @roomCodeCopied.
  ///
  /// In ru, this message translates to:
  /// **'Код скопирован'**
  String get roomCodeCopied;

  /// No description provided for @roomLeaveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Покинуть комнату?'**
  String get roomLeaveTitle;

  /// No description provided for @roomLeaveMessage.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите выйти из комнаты?'**
  String get roomLeaveMessage;

  /// No description provided for @roomLeaveCancel.
  ///
  /// In ru, this message translates to:
  /// **'Остаться'**
  String get roomLeaveCancel;

  /// No description provided for @roomLeaveConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get roomLeaveConfirm;

  /// No description provided for @roomPresenceLabel.
  ///
  /// In ru, this message translates to:
  /// **'В комнате'**
  String get roomPresenceLabel;

  /// No description provided for @roomEmptySeats.
  ///
  /// In ru, this message translates to:
  /// **'Ещё никого нет — пригласи по коду.'**
  String get roomEmptySeats;

  /// No description provided for @roomVideoProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Обработка видео: {progress}%'**
  String roomVideoProcessing(int progress);

  /// No description provided for @roomVideoWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание контента...'**
  String get roomVideoWaiting;

  /// No description provided for @roomTabChat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get roomTabChat;

  /// No description provided for @roomTabParticipants.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get roomTabParticipants;

  /// No description provided for @roomTabQueue.
  ///
  /// In ru, this message translates to:
  /// **'Очередь'**
  String get roomTabQueue;

  /// No description provided for @roomMicLabel.
  ///
  /// In ru, this message translates to:
  /// **'Голос. чат'**
  String get roomMicLabel;

  /// No description provided for @roomMicActiveLabel.
  ///
  /// In ru, this message translates to:
  /// **'Микрофон'**
  String get roomMicActiveLabel;

  /// No description provided for @roomMicEnableLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вкл. микрофон'**
  String get roomMicEnableLabel;

  /// No description provided for @roomSpeakerLabel.
  ///
  /// In ru, this message translates to:
  /// **'Динамик'**
  String get roomSpeakerLabel;

  /// No description provided for @roomSpeakerAltLabel.
  ///
  /// In ru, this message translates to:
  /// **'Разговорный'**
  String get roomSpeakerAltLabel;

  /// No description provided for @roomReactionsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Реакция'**
  String get roomReactionsLabel;

  /// No description provided for @roomReactionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Реакции'**
  String get roomReactionsTitle;

  /// No description provided for @chatPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение...'**
  String get chatPlaceholder;

  /// No description provided for @chatEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообщений'**
  String get chatEmpty;

  /// No description provided for @chatYouLabel.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get chatYouLabel;

  /// No description provided for @participantHostLabel.
  ///
  /// In ru, this message translates to:
  /// **'Хост'**
  String get participantHostLabel;

  /// No description provided for @participantHostRole.
  ///
  /// In ru, this message translates to:
  /// **'Управляет плеером'**
  String get participantHostRole;

  /// No description provided for @participantViewerRole.
  ///
  /// In ru, this message translates to:
  /// **'Зритель'**
  String get participantViewerRole;

  /// No description provided for @participantLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get participantLoadError;

  /// No description provided for @queueAddButton.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в очередь'**
  String get queueAddButton;

  /// No description provided for @queueEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Очередь пуста'**
  String get queueEmpty;

  /// No description provided for @queueProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Обработка: {progress}%'**
  String queueProcessing(int progress);

  /// No description provided for @queueError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get queueError;

  /// No description provided for @queueLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get queueLoadError;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Я'**
  String get profileTitle;

  /// No description provided for @profileLabel.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileLabel;

  /// No description provided for @profileGuestLabel.
  ///
  /// In ru, this message translates to:
  /// **'Гость'**
  String get profileGuestLabel;

  /// No description provided for @profileGuestHandle.
  ///
  /// In ru, this message translates to:
  /// **'— · войдите'**
  String get profileGuestHandle;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profileSettingsTitle;

  /// No description provided for @profileNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get profileNotifications;

  /// No description provided for @profileNotificationsOn.
  ///
  /// In ru, this message translates to:
  /// **'Вкл'**
  String get profileNotificationsOn;

  /// No description provided for @profileNotificationsOff.
  ///
  /// In ru, this message translates to:
  /// **'Выкл'**
  String get profileNotificationsOff;

  /// No description provided for @profileLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get profileLanguage;

  /// No description provided for @profileLanguageRu.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get profileLanguageRu;

  /// No description provided for @profileLanguageEn.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get profileLanguageEn;

  /// No description provided for @profileMicrophone.
  ///
  /// In ru, this message translates to:
  /// **'Микрофон'**
  String get profileMicrophone;

  /// No description provided for @profileMicrophoneDefault.
  ///
  /// In ru, this message translates to:
  /// **'По умолч.'**
  String get profileMicrophoneDefault;

  /// No description provided for @profileAboutTitle.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get profileAboutTitle;

  /// No description provided for @profileVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get profileVersion;

  /// No description provided for @profileLicenses.
  ///
  /// In ru, this message translates to:
  /// **'Лицензии'**
  String get profileLicenses;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите выйти?'**
  String get profileLogoutConfirmMessage;

  /// No description provided for @profileLogoutCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get profileLogoutCancel;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogoutConfirm;

  /// No description provided for @profileLoginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти в аккаунт'**
  String get profileLoginButton;

  /// No description provided for @profileRegisterButton.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get profileRegisterButton;

  /// No description provided for @profileSessionsLabel.
  ///
  /// In ru, this message translates to:
  /// **'сеансов'**
  String get profileSessionsLabel;

  /// No description provided for @profileHoursLabel.
  ///
  /// In ru, this message translates to:
  /// **'часов'**
  String get profileHoursLabel;

  /// No description provided for @profileFriendsLabel.
  ///
  /// In ru, this message translates to:
  /// **'друзей'**
  String get profileFriendsLabel;

  /// No description provided for @profileStatsPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'—'**
  String get profileStatsPlaceholder;

  /// No description provided for @sessionsHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Последние сеансы'**
  String get sessionsHistoryTitle;

  /// No description provided for @sessionsHistoryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока ни одного сеанса'**
  String get sessionsHistoryEmpty;

  /// No description provided for @sessionsHistoryEnter.
  ///
  /// In ru, this message translates to:
  /// **'Зайти'**
  String get sessionsHistoryEnter;

  /// No description provided for @sessionsHistoryRoomTitle.
  ///
  /// In ru, this message translates to:
  /// **'Комната {code}'**
  String sessionsHistoryRoomTitle(String code);

  /// No description provided for @sessionsHistoryDurationHours.
  ///
  /// In ru, this message translates to:
  /// **'{h} ч {m} мин'**
  String sessionsHistoryDurationHours(int h, int m);

  /// No description provided for @sessionsHistoryDurationMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{m} мин'**
  String sessionsHistoryDurationMinutes(int m);

  /// No description provided for @sessionsHistoryDurationSeconds.
  ///
  /// In ru, this message translates to:
  /// **'{s} с'**
  String sessionsHistoryDurationSeconds(int s);

  /// No description provided for @sessionsHistoryAgoJustNow.
  ///
  /// In ru, this message translates to:
  /// **'только что'**
  String get sessionsHistoryAgoJustNow;

  /// No description provided for @sessionsHistoryAgoMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{n} мин назад'**
  String sessionsHistoryAgoMinutes(int n);

  /// No description provided for @sessionsHistoryAgoHours.
  ///
  /// In ru, this message translates to:
  /// **'{n} ч назад'**
  String sessionsHistoryAgoHours(int n);

  /// No description provided for @sessionsHistoryAgoDays.
  ///
  /// In ru, this message translates to:
  /// **'{n} дн назад'**
  String sessionsHistoryAgoDays(int n);

  /// No description provided for @sessionsHistoryError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get sessionsHistoryError;

  /// No description provided for @navRecs.
  ///
  /// In ru, this message translates to:
  /// **'Подборки'**
  String get navRecs;

  /// No description provided for @recsFeedDateLabel.
  ///
  /// In ru, this message translates to:
  /// **'{date} · {time}'**
  String recsFeedDateLabel(String date, String time);

  /// No description provided for @recsFeedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что посмотреть'**
  String get recsFeedTitle;

  /// No description provided for @recsFeedTitleAccent.
  ///
  /// In ru, this message translates to:
  /// **'вечером?'**
  String get recsFeedTitleAccent;

  /// No description provided for @recsFeedFreeNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас в сети'**
  String get recsFeedFreeNow;

  /// No description provided for @recsFeedFreeCount.
  ///
  /// In ru, this message translates to:
  /// **'{n} в сети'**
  String recsFeedFreeCount(int n);

  /// No description provided for @recsFeedTopMatch.
  ///
  /// In ru, this message translates to:
  /// **'Топ-совпадение'**
  String get recsFeedTopMatch;

  /// No description provided for @recsFeedFriendWantsToWatch.
  ///
  /// In ru, this message translates to:
  /// **'{name} хочет посмотреть'**
  String recsFeedFriendWantsToWatch(String name);

  /// No description provided for @recsFeedMoodsLabel.
  ///
  /// In ru, this message translates to:
  /// **'По настроению'**
  String get recsFeedMoodsLabel;

  /// No description provided for @recsFeedTopKpLabel.
  ///
  /// In ru, this message translates to:
  /// **'Высокий рейтинг КиноПоиска'**
  String get recsFeedTopKpLabel;

  /// No description provided for @recsFeedMatchPercent.
  ///
  /// In ru, this message translates to:
  /// **'{n}% совпадение'**
  String recsFeedMatchPercent(int n);

  /// No description provided for @recsFeedFriendsLikeIt.
  ///
  /// In ru, this message translates to:
  /// **'понравится {n}'**
  String recsFeedFriendsLikeIt(int n);

  /// No description provided for @recsFeedInvite.
  ///
  /// In ru, this message translates to:
  /// **'Позвать'**
  String get recsFeedInvite;

  /// No description provided for @recsFeedEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока пусто. Добавьте подборки в админке.'**
  String get recsFeedEmpty;

  /// No description provided for @recsFeedMoodMoviesCount.
  ///
  /// In ru, this message translates to:
  /// **'{n} фильмов'**
  String recsFeedMoodMoviesCount(int n);

  /// No description provided for @recsPresenceFree.
  ///
  /// In ru, this message translates to:
  /// **'в сети'**
  String get recsPresenceFree;

  /// No description provided for @recsPresenceBusy.
  ///
  /// In ru, this message translates to:
  /// **'в комнате'**
  String get recsPresenceBusy;

  /// No description provided for @recsPresenceIdle.
  ///
  /// In ru, this message translates to:
  /// **'не в сети'**
  String get recsPresenceIdle;

  /// No description provided for @recsMatchHeader.
  ///
  /// In ru, this message translates to:
  /// **'совпадение вкусов'**
  String get recsMatchHeader;

  /// No description provided for @recsMatchPairLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ты и {name}'**
  String recsMatchPairLabel(String name);

  /// No description provided for @recsMatchOverlapStat.
  ///
  /// In ru, this message translates to:
  /// **'{percent}% общих вкусов · {count} совпадений'**
  String recsMatchOverlapStat(int percent, int count);

  /// No description provided for @recsMatchSharedTags.
  ///
  /// In ru, this message translates to:
  /// **'Любите оба'**
  String get recsMatchSharedTags;

  /// No description provided for @recsMatchListLabel.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуем вдвоём'**
  String get recsMatchListLabel;

  /// No description provided for @recsMatchInsufficient.
  ///
  /// In ru, this message translates to:
  /// **'Соберите больше истории — пересечения появятся, когда у каждого будет 3+ просмотра.'**
  String get recsMatchInsufficient;

  /// No description provided for @recsMatchCta.
  ///
  /// In ru, this message translates to:
  /// **'Создать комнату с {name}'**
  String recsMatchCta(String name);

  /// No description provided for @recsMoodHeader.
  ///
  /// In ru, this message translates to:
  /// **'Настроение'**
  String get recsMoodHeader;

  /// No description provided for @recsMoodTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня хочется'**
  String get recsMoodTitle;

  /// No description provided for @recsMoodTitleAccent.
  ///
  /// In ru, this message translates to:
  /// **'{mood}.'**
  String recsMoodTitleAccent(String mood);

  /// No description provided for @recsMoodEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В этой подборке пока пусто'**
  String get recsMoodEmpty;

  /// No description provided for @recsTitleMatchHeader.
  ///
  /// In ru, this message translates to:
  /// **'{percent}% совпадение'**
  String recsTitleMatchHeader(int percent);

  /// No description provided for @recsTitleWhy.
  ///
  /// In ru, this message translates to:
  /// **'Почему рекомендуем'**
  String get recsTitleWhy;

  /// No description provided for @recsTitleWillLike.
  ///
  /// In ru, this message translates to:
  /// **'Понравится'**
  String get recsTitleWillLike;

  /// No description provided for @recsTitleCta.
  ///
  /// In ru, this message translates to:
  /// **'Позвать {names}'**
  String recsTitleCta(String names);

  /// No description provided for @recsTitleCtaJoinSelf.
  ///
  /// In ru, this message translates to:
  /// **'Создать комнату'**
  String get recsTitleCtaJoinSelf;

  /// No description provided for @recsTitleIntentAdd.
  ///
  /// In ru, this message translates to:
  /// **'Хочу посмотреть'**
  String get recsTitleIntentAdd;

  /// No description provided for @recsTitleIntentRemove.
  ///
  /// In ru, this message translates to:
  /// **'Передумал'**
  String get recsTitleIntentRemove;

  /// No description provided for @onboardingTagTogether.
  ///
  /// In ru, this message translates to:
  /// **'01 — Together'**
  String get onboardingTagTogether;

  /// No description provided for @onboardingTagOneRoom.
  ///
  /// In ru, this message translates to:
  /// **'02 — В одной комнате'**
  String get onboardingTagOneRoom;

  /// No description provided for @onboardingTagAnySource.
  ///
  /// In ru, this message translates to:
  /// **'03 — Любой источник'**
  String get onboardingTagAnySource;

  /// No description provided for @onboardingSourceTagsLine.
  ///
  /// In ru, this message translates to:
  /// **'FILES · TORRENT · RUTUBE · VOICE'**
  String get onboardingSourceTagsLine;

  /// No description provided for @onboardingScreenSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'«Мы в одной комнате.»'**
  String get onboardingScreenSubtitle;

  /// No description provided for @onboardingSourceFile.
  ///
  /// In ru, this message translates to:
  /// **'Файл'**
  String get onboardingSourceFile;

  /// No description provided for @onboardingSourceFileExt.
  ///
  /// In ru, this message translates to:
  /// **'.mp4 · .mkv\n.webm · .mov'**
  String get onboardingSourceFileExt;

  /// No description provided for @onboardingSourceFileBadge.
  ///
  /// In ru, this message translates to:
  /// **'Самое популярное'**
  String get onboardingSourceFileBadge;

  /// No description provided for @onboardingSourceTorrent.
  ///
  /// In ru, this message translates to:
  /// **'Торрент'**
  String get onboardingSourceTorrent;

  /// No description provided for @onboardingSourceTorrentExt.
  ///
  /// In ru, this message translates to:
  /// **'.torrent / magnet'**
  String get onboardingSourceTorrentExt;

  /// No description provided for @onboardingSourceRutube.
  ///
  /// In ru, this message translates to:
  /// **'Rutube'**
  String get onboardingSourceRutube;

  /// No description provided for @onboardingSourceRutubeExt.
  ///
  /// In ru, this message translates to:
  /// **'rutube.ru/...'**
  String get onboardingSourceRutubeExt;

  /// No description provided for @onboardingSourceStream.
  ///
  /// In ru, this message translates to:
  /// **'Стрим'**
  String get onboardingSourceStream;

  /// No description provided for @onboardingSourceStreamExt.
  ///
  /// In ru, this message translates to:
  /// **'HLS / m3u8'**
  String get onboardingSourceStreamExt;

  /// No description provided for @editProfileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get editProfileTitle;

  /// No description provided for @editProfileUsername.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя'**
  String get editProfileUsername;

  /// No description provided for @editProfileEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get editProfileEmail;

  /// No description provided for @editProfileSaveButton.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get editProfileSaveButton;

  /// No description provided for @editProfileEmptyError.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя не может быть пустым'**
  String get editProfileEmptyError;

  /// No description provided for @editProfileError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {message}'**
  String editProfileError(String message);

  /// No description provided for @createRoomTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создать комнату'**
  String get createRoomTitle;

  /// No description provided for @createRoomSourceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Источник контента'**
  String get createRoomSourceLabel;

  /// No description provided for @sourceFile.
  ///
  /// In ru, this message translates to:
  /// **'Файл'**
  String get sourceFile;

  /// No description provided for @sourceTorrent.
  ///
  /// In ru, this message translates to:
  /// **'Торрент'**
  String get sourceTorrent;

  /// No description provided for @sourceRutube.
  ///
  /// In ru, this message translates to:
  /// **'Rutube'**
  String get sourceRutube;

  /// No description provided for @createRoomSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Название фильма или сериала'**
  String get createRoomSearchHint;

  /// No description provided for @createRoomMagnetHint.
  ///
  /// In ru, this message translates to:
  /// **'или вставьте magnet-ссылку'**
  String get createRoomMagnetHint;

  /// No description provided for @createRoomRutubeHint.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка на Rutube'**
  String get createRoomRutubeHint;

  /// No description provided for @createRoomButton.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get createRoomButton;

  /// No description provided for @createRoomMagnetButton.
  ///
  /// In ru, this message translates to:
  /// **'Создать по ссылке'**
  String get createRoomMagnetButton;

  /// No description provided for @createRoomFileError.
  ///
  /// In ru, this message translates to:
  /// **'Выберите файл'**
  String get createRoomFileError;

  /// No description provided for @createRoomUrlError.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте ссылку'**
  String get createRoomUrlError;

  /// No description provided for @createRoomSearchError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка поиска: {message}'**
  String createRoomSearchError(String message);

  /// No description provided for @createRoomError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {message}'**
  String createRoomError(String message);

  /// No description provided for @createRoomMagnetError.
  ///
  /// In ru, this message translates to:
  /// **'У результата нет magnet-ссылки'**
  String get createRoomMagnetError;

  /// No description provided for @createRoomFileReadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать файл'**
  String get createRoomFileReadError;

  /// No description provided for @createRoomUploadHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите для выбора файла'**
  String get createRoomUploadHint;

  /// No description provided for @createRoomFileFormats.
  ///
  /// In ru, this message translates to:
  /// **'MP4, MKV, AVI, MOV — до 10 ГБ'**
  String get createRoomFileFormats;

  /// No description provided for @joinRoomTitle.
  ///
  /// In ru, this message translates to:
  /// **'Присоединиться'**
  String get joinRoomTitle;

  /// No description provided for @joinRoomHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите 6-значный код приглашения'**
  String get joinRoomHint;

  /// No description provided for @joinRoomCodeError.
  ///
  /// In ru, this message translates to:
  /// **'Код должен содержать 6 символов'**
  String get joinRoomCodeError;

  /// No description provided for @joinRoomButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти в комнату'**
  String get joinRoomButton;

  /// No description provided for @joinRoomError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось присоединиться к комнате'**
  String get joinRoomError;

  /// No description provided for @addMediaTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в очередь'**
  String get addMediaTitle;

  /// No description provided for @addMediaSourceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Источник'**
  String get addMediaSourceLabel;

  /// No description provided for @addMediaSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Название фильма или сериала'**
  String get addMediaSearchHint;

  /// No description provided for @addMediaMagnetHint.
  ///
  /// In ru, this message translates to:
  /// **'или вставьте magnet-ссылку'**
  String get addMediaMagnetHint;

  /// No description provided for @addMediaRutubeHint.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка на Rutube'**
  String get addMediaRutubeHint;

  /// No description provided for @addMediaButton.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get addMediaButton;

  /// No description provided for @addMediaMagnetButton.
  ///
  /// In ru, this message translates to:
  /// **'Добавить по ссылке'**
  String get addMediaMagnetButton;

  /// No description provided for @addMediaFileError.
  ///
  /// In ru, this message translates to:
  /// **'Выберите файл'**
  String get addMediaFileError;

  /// No description provided for @addMediaUrlError.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте ссылку'**
  String get addMediaUrlError;

  /// No description provided for @addMediaSearchError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка поиска: {message}'**
  String addMediaSearchError(String message);

  /// No description provided for @addMediaError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {message}'**
  String addMediaError(String message);

  /// No description provided for @addMediaMagnetError.
  ///
  /// In ru, this message translates to:
  /// **'У результата нет magnet-ссылки'**
  String get addMediaMagnetError;

  /// No description provided for @addMediaFileReadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать файл'**
  String get addMediaFileReadError;

  /// No description provided for @addMediaUploadHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите для выбора файла'**
  String get addMediaUploadHint;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get navHome;

  /// No description provided for @navRooms.
  ///
  /// In ru, this message translates to:
  /// **'Комнаты'**
  String get navRooms;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Я'**
  String get navProfile;

  /// No description provided for @friendsScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Друзья'**
  String get friendsScreenTitle;

  /// No description provided for @friendsTabFriends.
  ///
  /// In ru, this message translates to:
  /// **'Друзья'**
  String get friendsTabFriends;

  /// No description provided for @friendsTabRequests.
  ///
  /// In ru, this message translates to:
  /// **'Заявки'**
  String get friendsTabRequests;

  /// No description provided for @friendsTabRequestsBadge.
  ///
  /// In ru, this message translates to:
  /// **'Заявки ({count})'**
  String friendsTabRequestsBadge(int count);

  /// No description provided for @friendsTabSearch.
  ///
  /// In ru, this message translates to:
  /// **'Найти'**
  String get friendsTabSearch;

  /// No description provided for @friendsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока никого'**
  String get friendsEmpty;

  /// No description provided for @friendsEmptyDesc.
  ///
  /// In ru, this message translates to:
  /// **'Найдите друга по имени и отправьте заявку.'**
  String get friendsEmptyDesc;

  /// No description provided for @friendsRequestsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Заявок нет'**
  String get friendsRequestsEmpty;

  /// No description provided for @friendsSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя'**
  String get friendsSearchHint;

  /// No description provided for @friendsSearchEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Никто не нашёлся'**
  String get friendsSearchEmpty;

  /// No description provided for @friendsActionAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get friendsActionAdd;

  /// No description provided for @friendsActionPending.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отправлена'**
  String get friendsActionPending;

  /// No description provided for @friendsActionAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get friendsActionAccept;

  /// No description provided for @friendsActionDecline.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get friendsActionDecline;

  /// No description provided for @friendsActionRemove.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get friendsActionRemove;

  /// No description provided for @friendsRemoveConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из друзей?'**
  String get friendsRemoveConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
