import 'package:flutter/foundation.dart';

import 'unsaved_work_guard_stub.dart'
    if (dart.library.js_interop) 'unsaved_work_guard_web.dart' as platform;

/// Tells the browser whether closing the tab would interrupt real work.
///
/// The page-level `beforeunload` listener in `web/index.html` reads the flag
/// this sets. Outside the browser it is a no-op, so tests and any future
/// non-web target are unaffected.
class UnsavedWorkGuard {
  UnsavedWorkGuard._();

  static bool _current = false;

  static void set(bool hasUnsavedWork) {
    if (_current == hasUnsavedWork) return;
    _current = hasUnsavedWork;
    if (!kIsWeb) return;
    platform.setUnsavedWorkFlag(hasUnsavedWork);
  }
}
