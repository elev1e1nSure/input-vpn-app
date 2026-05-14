import 'package:flutter/material.dart';

/// Lightweight localization without gen-l10n boilerplate.
/// Add new keys here and provide both English and Russian.
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;
  bool get isRu => locale.languageCode == 'ru';

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        AppStrings(const Locale('en'));
  }

  // --- HomePage ---
  String get setupRequired => isRu ? 'Требуется настройка' : 'Setup Required';
  String get connectInOneMinute => isRu ? 'Подключите VPN' : 'Connect VPN';
  String get emptyStateSubtitle => isRu
      ? 'Импортируйте конфиг, отсканируйте QR или вставьте ссылку'
      : 'Import a config, scan a QR code, or paste a link';
  String get connecting => isRu ? 'Подключение...' : 'Connecting...';
  String get connected => isRu ? 'Подключено' : 'Connected';
  String get disconnecting => isRu ? 'Отключение...' : 'Disconnecting...';
  String get readyToConnect => isRu ? 'Готово к подключению' : 'Ready to Connect';
  String get pleaseAddConfig => isRu ? 'Добавьте конфигурацию' : 'Please add a configuration';
  String get yourIpIsHidden => isRu ? 'Ваш IP скрыт' : 'Your IP is hidden';
  String get securityLevelHigh => isRu ? 'Уровень защиты: высокий' : 'Security level: High';
  String get selectedServer => isRu ? 'Выбранный сервер' : 'Selected Server';
  String get noServer => isRu ? 'Нет сервера' : 'No Server';
  String get addAConfiguration => isRu ? 'Добавить конфигурацию' : 'Add a configuration';
  String get addConfigurationBtn => isRu ? 'Добавить конфигурацию' : 'Add Configuration';
  String get connect => isRu ? 'Подключить' : 'Connect';
  String get disconnect => isRu ? 'Отключить' : 'Disconnect';
  String get disconnectedStatus => isRu ? 'Отключено' : 'Disconnected';
  String get ping => isRu ? 'ПИНГ' : 'PING';
  String get download => isRu ? 'СКАЧИВАНИЕ' : 'DOWNLOAD';
  String get upload => isRu ? 'ОТПРАВКА' : 'UPLOAD';

  // --- Onboarding Quick Actions ---
  String get importConfig => isRu ? 'Импорт' : 'Import';
  String get scanQR => isRu ? 'Скан QR' : 'Scan QR';
  String get getConfig => isRu ? 'Получить' : 'Get Config';

  // --- Trust / Micro-info ---
  String get configsStoredLocally => isRu ? 'Конфигурации хранятся локально' : 'Configs stored locally';
  String get supportsWireGuardOpenVPN => isRu ? 'Поддержка VLESS / VMess / SS / Trojan' : 'VLESS / VMess / SS / Trojan support';

  // --- Mock server states ---
  String get offline => isRu ? 'Offline' : 'Offline';
  String get notConfigured => isRu ? 'Не настроен' : 'Not configured';

  // --- Mode toggle ---
  String get vpnLabel => isRu ? 'VPN' : 'VPN';
  String get socks5Label => isRu ? 'SOCKS5' : 'SOCKS5';

  // --- ServersScreen ---
  String get myServers => isRu ? 'Мои серверы' : 'My Servers';
  String get noServersYet => isRu ? 'Серверов пока нет' : 'No Servers Yet';
  String get addFirstConfigHint => isRu
      ? 'Добавьте первую конфигурацию или ссылку на подписку.'
      : 'Add your first configuration or subscription link to get started.';
  String get addConfig => isRu ? 'Добавить' : 'Add Config';
  String get deleteServer => isRu ? 'Удалить сервер' : 'Delete Server';

  // --- AddConfigScreen ---
  String get addConfiguration => isRu ? 'Добавить конфигурацию' : 'Add Configuration';
  String get editConfiguration => isRu ? 'Изменить конфигурацию' : 'Edit Configuration';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get add => isRu ? 'Добавить' : 'Add';
  String get importFromFile => isRu ? 'Импорт' : 'Import';
  String get scanQRCode => isRu ? 'Скан QR' : 'Scan QR';
  String get displayName => isRu ? 'Название' : 'Name';
  String get displayNameHint => isRu ? 'Напр. Мой Premium VLESS' : 'e.g. My Premium VLESS';
  String get type => isRu ? 'Тип' : 'Type';
  String get configOrUrl => isRu ? 'Конфиг или ссылка' : 'Config or link';
  String get supportedFormats => isRu
      ? 'Поддерживаемые форматы: vless://, vmess://, ss://, trojan:// или ссылка на подписку (HTTP/HTTPS).'
      : 'Supported formats: vless://, vmess://, ss://, trojan:// or a subscription link (HTTP/HTTPS).';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get delete => isRu ? 'Удалить' : 'Delete';
  String get vlessVmessSs => isRu ? 'VLESS / VMess / SS' : 'VLESS / VMess / SS';
  String get subscriptionUrl => isRu ? 'Ссылка на подписку' : 'Subscription URL';

  // --- Settings ---
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get connection => isRu ? 'ПОДКЛЮЧЕНИЕ' : 'CONNECTION';
  String get appearance => isRu ? 'ВНЕШНИЙ ВИД' : 'APPEARANCE';
  String get advanced => isRu ? 'Дополнительно' : 'Advanced';
  String get about => isRu ? 'О ПРИЛОЖЕНИИ' : 'ABOUT';
  String get vpnProtocol => isRu ? 'Протокол VPN' : 'VPN Protocol';
  String get killSwitch => isRu ? 'Kill Switch' : 'Kill Switch';
  String get connectOnBoot => isRu ? 'Подключать при запуске' : 'Connect on Boot';
  String get autoLaunch => isRu ? 'Запускать при старте Windows' : 'Launch on startup';
  String get darkMode => isRu ? 'Тёмная тема' : 'Dark Mode';
  String get splitTunneling => isRu ? 'Раздельное туннелирование' : 'Split Tunneling';
  String get customDns => isRu ? 'DNS' : 'Custom DNS';
  String get customDnsProfilesTitle =>
      isRu ? 'Пользовательские DNS' : 'Custom DNS Profiles';
  String get customDnsEmpty => isRu
      ? 'Добавь профиль DNS, чтобы выбрать его в настройках.'
      : 'Add a DNS profile to select it inside settings.';
  String get manageCustomDns =>
      isRu ? 'Управлять пользовательскими DNS' : 'Manage custom DNS';
  String get primaryDns => isRu ? 'Основной DNS' : 'Primary DNS';
  String get secondaryDns => isRu ? 'Резервный DNS' : 'Secondary DNS';
  String get proxyMode => isRu ? 'Режим прокси' : 'Proxy Mode';
  String get vpnMode => isRu ? 'Режим VPN' : 'VPN Mode';
  String get version => isRu ? 'Версия' : 'Version';
  String get checkForUpdates => isRu ? 'Проверить обновления' : 'Check for Updates';
  String get upToDate => isRu ? 'Актуальная версия' : 'Up to Date';
  String get updateAvailable => isRu ? 'Доступно обновление' : 'Update Available';
  String get updateNow => isRu ? 'Обновить' : 'Update Now';
  String get downloadingUpdate => isRu ? 'Скачивание обновления' : 'Downloading update';
  String get updateReady => isRu ? 'Готово к установке' : 'Ready to install';
  String get updateWillClose =>
      isRu ? 'Приложение закроется для установки обновления.' : 'The app will close to install the update.';
  String get check => isRu ? 'Проверить' : 'Check';
  String get minimizeToTray => isRu ? 'Сворачивать в трей' : 'Minimize to Tray';
  String get language => isRu ? 'Язык' : 'Language';
  String get exportSettings => isRu ? 'Экспорт настроек' : 'Export Settings';
  String get importSettings => isRu ? 'Импорт настроек' : 'Import Settings';
  String get settingsCopied =>
      isRu ? 'Настройки скопированы в буфер обмена' : 'Settings copied to clipboard';
  String get settingsImported =>
      isRu ? 'Настройки применены' : 'Settings imported';
  String get settingsImportFailed =>
      isRu ? 'Не удалось импортировать настройки' : 'Failed to import settings';

  // --- Settings ---
  String get basic => isRu ? 'ОБЫЧНЫЕ' : 'BASIC';
  String get dnsServer => isRu ? 'DNS-сервер' : 'DNS Server';
  String get proxyPort => isRu ? 'Порт прокси' : 'Proxy Port';
  String get recommended => isRu ? 'Рекомендуется' : 'Recommended';
  String get standard => isRu ? 'Стандарт' : 'Standard';
  String get noAds => isRu ? 'Без рекламы' : 'No ads';
  String get system => isRu ? 'Системный' : 'System';

  // --- Misc ---
  String get copy => isRu ? 'Копировать' : 'Copy';
  String get dismiss => isRu ? 'Закрыть' : 'Dismiss';
  String get unexpectedError => isRu ? 'Неожиданная ошибка' : 'Unexpected error';
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
