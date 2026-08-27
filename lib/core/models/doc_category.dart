import '../services/i18n/translations.g.dart';

enum DocCategory { gods, cosmogonies, myths }

extension DocCategoryX on DocCategory {
  String get folder => switch (this) {
    DocCategory.gods => 'gods',
    DocCategory.cosmogonies => 'cosmogonies',
    DocCategory.myths => 'myths',
  };

  String title(Translations t) => switch (this) {
    DocCategory.gods => t.gods,
    DocCategory.cosmogonies => t.cosmogonies,
    DocCategory.myths => t.myths,
  };

  String shareText(Translations t, String value) => switch (this) {
    DocCategory.gods => t.godsShare(value: value),
    DocCategory.cosmogonies => t.cosmogoniesShare(value: value),
    DocCategory.myths => t.mythsShare(value: value),
  };
}
