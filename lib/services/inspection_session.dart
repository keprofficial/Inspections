class InspectionSession {
  InspectionSession._();

  static String? _profileId;
  static String? _propertyId;
  static String? _inspectionId;
  static String? _keprId;
  static String? _societyName;
  static String? _flatNumber;

  static String? get profileId => _profileId;
  static String? get propertyId => _propertyId;
  static String? get inspectionId => _inspectionId;
  static String? get keprId => _keprId;
  static String? get societyName => _societyName;
  static String? get flatNumber => _flatNumber;

  static set profileId(String? value) => _profileId = value;
  static set propertyId(String? value) => _propertyId = value;
  static set inspectionId(String? value) => _inspectionId = value;
  static set keprId(String? value) => _keprId = value;
  static set societyName(String? value) => _societyName = value;
  static set flatNumber(String? value) => _flatNumber = value;

  static void clear() {
    _profileId = null;
    _propertyId = null;
    _inspectionId = null;
    _keprId = null;
    _societyName = null;
    _flatNumber = null;
  }

  static bool get isActive =>
      _profileId != null && _propertyId != null && _inspectionId != null;
}
