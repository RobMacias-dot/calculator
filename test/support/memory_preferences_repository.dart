import 'package:engineering_toolkit/features/preferences/preferences_repository.dart';

class MemoryPreferencesRepository implements PreferencesRepository {
  MemoryPreferencesRepository([Preferences? initial])
    : value = initial ?? Preferences();
  Preferences value;
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;

  @override
  Future<Preferences> read() async {
    if (failRead) throw StateError('Storage unavailable');
    return value;
  }

  @override
  Future<void> write(Preferences preferences) async {
    writes++;
    if (failWrite) throw StateError('Storage unavailable');
    value = preferences;
  }
}
