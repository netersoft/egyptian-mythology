import '../../models/doc_category.dart';
import '../di/locator.dart';
import '../shared_preferences/keys.dart';
import '../shared_preferences/service.dart';

// Remembers, per documentation category, which page the reader was on and
// how far down it they had scrolled, so reopening the category resumes there
// instead of restarting from the introduction.
class ReadingProgressRepository {
  SharedPreferencesService get _prefs => locator<SharedPreferencesService>();

  String? lastItemId(DocCategory category) => _prefs.getString(PrefKeys.docLastItem(category.folder));

  double lastOffset(DocCategory category) => _prefs.getDouble(PrefKeys.docLastOffset(category.folder)) ?? 0;

  Future<void> save(DocCategory category, String itemId, double offset) async {
    await _prefs.setString(PrefKeys.docLastItem(category.folder), itemId);
    await _prefs.setDouble(PrefKeys.docLastOffset(category.folder), offset);
  }
}
