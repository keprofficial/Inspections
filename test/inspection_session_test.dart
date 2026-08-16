import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/services/inspection_session.dart';

void main() {
  tearDown(InspectionSession.clear);

  test('individual inspection is active without a profile row', () {
    InspectionSession.inspectionMode = 'individual';
    InspectionSession.propertyId = 'individual-property-ref';
    InspectionSession.inspectionId = 'individual-inspection-ref';

    expect(InspectionSession.profileId, isNull);
    expect(InspectionSession.isActive, isTrue);
  });

  test('flat inspection still requires a profile row', () {
    InspectionSession.inspectionMode = 'flat';
    InspectionSession.propertyId = 'property-id';
    InspectionSession.inspectionId = 'inspection-id';

    expect(InspectionSession.isActive, isFalse);

    InspectionSession.profileId = 'profile-id';
    expect(InspectionSession.isActive, isTrue);
  });
}
