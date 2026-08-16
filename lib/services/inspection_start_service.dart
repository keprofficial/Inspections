import 'inspection_draft_storage.dart';
import 'inspection_session.dart';
import 'supabase_repository.dart';

/// Where the caller should go once an inspection has been started.
enum StartDestination {
  /// The inspection is ready — open the Inspect tab.
  inspection,

  /// The selected flat has no live property row yet — collect details first.
  propertyDetails,
}

/// Starts flat, society, and individual inspections.
///
/// Extracted verbatim from `SignInScreen` so the start rules live in one
/// testable place instead of inside a 1600-line widget. Every session field,
/// RPC call, and validation is preserved.
class InspectionStartService {
  InspectionStartService._();

  static final InspectionStartService instance = InspectionStartService._();

  /// True when the backend rejected the inspector's session token and the
  /// user must log in again.
  static bool isExpiredSessionError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('expired inspector session') ||
        text.contains('invalid or expired') ||
        text.contains('session_token') ||
        text.contains('session token');
  }

  Future<StartDestination> startFlatInspection({
    required InspectorLogin authenticatedInspector,
    required PropertyOption society,
    required PropertyOption block,
    required PropertyOption flat,
    required String inspectionPlan,
  }) async {
    if (authenticatedInspector.authToken == null) {
      throw Exception('Please sign in first.');
    }
    await InspectionDraftStorage.clearAreas();
    InspectionSession.beginInspectionScope('flat');
    final login = SupabaseRepository.instance.createInspectorLoginFromSelection(
      authenticatedInspector: authenticatedInspector,
      society: society,
      block: block,
      flat: flat,
    );

    InspectionSession.inspectorId = login.userId;
    InspectionSession.inspectorName = login.displayName;
    InspectionSession.mobileNumber = login.phone;
    InspectionSession.authToken = login.authToken;
    InspectionSession.inspectionPlan = inspectionPlan;
    InspectionSession.inspectionCode = null;
    InspectionSession.propertyOwnerName = null;
    InspectionSession.propertyOwnerMobile = null;

    final property = login.property;
    if (property != null) {
      InspectionSession.profileId = property.profileId;
      InspectionSession.propertyId = property.propertyId;
      InspectionSession.keprId = property.propertyCode;
      InspectionSession.societyName = property.propertyName;
      InspectionSession.flatNumber = property.block;
      final started = await SupabaseRepository.instance.startInspection(
        propertyId: property.propertyId,
        authToken: login.authToken!,
        inspectionType: 'flat',
        title: 'Flat Inspection - '
            '${property.block ?? property.propertyName ?? property.propertyCode ?? property.propertyId}',
        inspectorName: login.displayName,
      );
      if (started == null || started.inspectionType != 'flat') {
        throw Exception('Database did not create a flat inspection.');
      }
      InspectionSession.inspectionId = started.inspectionId;
      InspectionSession.inspectionCode = started.inspectionCode;
    }
    await InspectionDraftStorage.saveSession();

    return property == null
        ? StartDestination.propertyDetails
        : StartDestination.inspection;
  }

  Future<StartDestination> startSocietyInspection({
    required InspectorLogin authenticatedInspector,
    required PropertyOption society,
    required String inspectionPlan,
  }) async {
    if (authenticatedInspector.authToken == null) {
      throw Exception('Please sign in first.');
    }

    await InspectionDraftStorage.clearAreas();
    InspectionSession.beginInspectionScope('society');
    InspectionSession.inspectorId = authenticatedInspector.userId;
    InspectionSession.inspectorName = authenticatedInspector.displayName;
    InspectionSession.mobileNumber = authenticatedInspector.phone;
    InspectionSession.authToken = authenticatedInspector.authToken;
    InspectionSession.inspectionPlan = inspectionPlan;
    InspectionSession.inspectionCode = null;
    InspectionSession.profileId = society.id;
    InspectionSession.propertyId = society.id;
    InspectionSession.keprId = society.propertyCode;
    InspectionSession.societyName = society.name;
    InspectionSession.flatNumber = 'Society Inspection';
    InspectionSession.propertyOwnerName = null;
    InspectionSession.propertyOwnerMobile = null;

    // The database start RPC validates that the property is a society.
    final started = await SupabaseRepository.instance.startInspection(
      propertyId: society.id,
      authToken: authenticatedInspector.authToken!,
      inspectionType: 'society',
      title: 'Society Inspection - ${society.name}',
      inspectorName: authenticatedInspector.displayName,
    );
    if (started == null || started.inspectionType != 'society') {
      throw Exception('Database did not create a society inspection.');
    }
    InspectionSession.inspectionId = started.inspectionId;
    InspectionSession.inspectionCode = started.inspectionCode;

    await InspectionDraftStorage.saveSession();
    return StartDestination.inspection;
  }

  Future<StartDestination> startIndividualInspection({
    required InspectorLogin authenticatedInspector,
    required String propertyName,
    required String ownerName,
    required String ownerMobile,
    required String inspectionPlan,
  }) async {
    if (authenticatedInspector.authToken == null) {
      throw Exception('Please sign in first.');
    }

    final trimmedProperty = propertyName.trim();
    final trimmedOwner = ownerName.trim();
    final trimmedMobile = ownerMobile.trim();
    if (trimmedProperty.isEmpty ||
        trimmedOwner.isEmpty ||
        trimmedMobile.isEmpty) {
      throw Exception(
        'Property name, owner name, and owner mobile are required.',
      );
    }

    // Individual inspections have no KEPR property/profile row, so they use a
    // generated reference that must never reach normal inspection FK tables.
    final now = DateTime.now().microsecondsSinceEpoch;
    final inspectionRef = 'individual-$now';
    final inspectionCode = await SupabaseRepository.instance.nextInspectionCode(
      inspectionType: 'individual',
    );

    await InspectionDraftStorage.clearInspectionDraft();
    InspectionSession.beginInspectionScope('individual');
    InspectionSession.inspectorId = authenticatedInspector.userId;
    InspectionSession.inspectorName = authenticatedInspector.displayName;
    InspectionSession.mobileNumber = authenticatedInspector.phone;
    InspectionSession.authToken = authenticatedInspector.authToken;
    InspectionSession.inspectionPlan = inspectionPlan;
    InspectionSession.inspectionCode = inspectionCode;
    InspectionSession.propertyId = inspectionRef;
    InspectionSession.inspectionId = inspectionRef;
    InspectionSession.societyName = trimmedProperty;
    InspectionSession.flatNumber = 'Owner: $trimmedOwner';
    InspectionSession.propertyOwnerName = trimmedOwner;
    InspectionSession.propertyOwnerMobile = trimmedMobile;
    await InspectionDraftStorage.saveSession();

    return StartDestination.inspection;
  }
}
