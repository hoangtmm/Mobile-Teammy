enum AppLanguage { vi, en }

extension AppLanguageX on AppLanguage {
  String get displayName => switch (this) {
        AppLanguage.vi => 'Tiếng Việt',
        AppLanguage.en => 'English',
      };

  String get shortLabel => switch (this) {
        AppLanguage.vi => 'VI',
        AppLanguage.en => 'EN',
      };

  String get flag => switch (this) {
        AppLanguage.vi => '🇻🇳',
        AppLanguage.en => '🇬🇧',
      };
}
