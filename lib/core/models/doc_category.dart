import '../services/i18n/translations.g.dart';

enum DocCategory { gods, cosmogonies, myths, reference }

extension DocCategoryX on DocCategory {
  String get folder => switch (this) {
    DocCategory.gods => 'gods',
    DocCategory.cosmogonies => 'cosmogonies',
    DocCategory.myths => 'myths',
    DocCategory.reference => 'reference',
  };

  String title(Translations t) => switch (this) {
    DocCategory.gods => t.gods,
    DocCategory.cosmogonies => t.cosmogonies,
    DocCategory.myths => t.myths,
    DocCategory.reference => t.reference,
  };

  String shareText(Translations t, String value) => switch (this) {
    DocCategory.gods => t.godsShare(value: value),
    DocCategory.cosmogonies => t.cosmogoniesShare(value: value),
    DocCategory.myths => t.mythsShare(value: value),
    DocCategory.reference => t.referenceShare(value: value),
  };
}
