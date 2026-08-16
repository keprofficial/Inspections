import 'dart:js_interop';

@JS('keprHasUnsavedWork')
external set _keprHasUnsavedWork(bool value);

/// Sets the flag read by the `beforeunload` listener in `web/index.html`.
void setUnsavedWorkFlag(bool hasUnsavedWork) {
  _keprHasUnsavedWork = hasUnsavedWork;
}
