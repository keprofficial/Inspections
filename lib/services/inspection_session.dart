class InspectionSession {
  InspectionSession._();

  static String? _profileId;
  static String? _propertyId;
  static String? _inspectionId;
  static String? _inspectionCode;
  static String? _keprId;
  static String? _societyName;
  static String? _flatNumber;
  static String? _inspectorId;
  static String? _inspectorName;
  static String? _mobileNumber;
  static String? _authToken;
  static String? _inspectionMode;
  static String? _propertyOwnerName;
  static String? _propertyOwnerMobile;
  static DateTime? _lastLoginAt;

  static String? get profileId => _profileId;
  static String? get propertyId => _propertyId;
  static String? get inspectionId => _inspectionId;
  static String? get inspectionCode => _inspectionCode;
  static String? get keprId => _keprId;
  static String? get societyName => _societyName;
  static String? get flatNumber => _flatNumber;
  static String? get inspectorId => _inspectorId;
  static String? get inspectorName => _inspectorName;
  static String? get mobileNumber => _mobileNumber;
  static String? get authToken => _authToken;
  static String? get inspectionMode => _inspectionMode;
  static String? get propertyOwnerName => _propertyOwnerName;
  static String? get propertyOwnerMobile => _propertyOwnerMobile;
  static DateTime? get lastLoginAt => _lastLoginAt;
  static bool get hasFreshInspectorSession {
    final token = _authToken;
    final loginAt = _lastLoginAt;
    if (token == null || token.isEmpty || loginAt == null) return false;
    return DateTime.now().difference(loginAt) < const Duration(hours: 11);
  }

  static set profileId(String? value) => _profileId = value;
  static set propertyId(String? value) => _propertyId = value;
  static set inspectionId(String? value) => _inspectionId = value;
  static set inspectionCode(String? value) => _inspectionCode = value;
  static set keprId(String? value) => _keprId = value;
  static set societyName(String? value) => _societyName = value;
  static set flatNumber(String? value) => _flatNumber = value;
  static set inspectorId(String? value) => _inspectorId = value;
  static set inspectorName(String? value) => _inspectorName = value;
  static set mobileNumber(String? value) => _mobileNumber = value;
  static set authToken(String? value) => _authToken = value;
  static set inspectionMode(String? value) => _inspectionMode = value;
  static set propertyOwnerName(String? value) => _propertyOwnerName = value;
  static set propertyOwnerMobile(String? value) => _propertyOwnerMobile = value;
  static set lastLoginAt(DateTime? value) => _lastLoginAt = value;

  static bool get isIndividualInspection => _inspectionMode == 'individual';
  static bool get isSocietyInspection => _inspectionMode == 'society';

  static void clear() {
    _profileId = null;
    _propertyId = null;
    _inspectionId = null;
    _inspectionCode = null;
    _keprId = null;
    _societyName = null;
    _flatNumber = null;
    _inspectorId = null;
    _inspectorName = null;
    _mobileNumber = null;
    _authToken = null;
    _inspectionMode = null;
    _propertyOwnerName = null;
    _propertyOwnerMobile = null;
    _lastLoginAt = null;
  }

  static void clearInspection() {
    _profileId = null;
    _propertyId = null;
    _inspectionId = null;
    _inspectionCode = null;
    _keprId = null;
    _societyName = null;
    _flatNumber = null;
    _inspectionMode = null;
    _propertyOwnerName = null;
    _propertyOwnerMobile = null;
  }

  static void clearInspectorAuth() {
    _inspectorId = null;
    _inspectorName = null;
    _mobileNumber = null;
    _authToken = null;
    _lastLoginAt = null;
  }

  static bool get isActive =>
      _profileId != null && _propertyId != null && _inspectionId != null;
}
