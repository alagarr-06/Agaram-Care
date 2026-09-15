// Task 09 - Agaram Care Patient Care Request Model.
library;

import '../../../triage/domain/action/next_best_action.dart';
import '../../../triage/domain/enums/next_action_type.dart';
import '../../../triage/domain/enums/triage_urgency.dart';
import '../../../triage/domain/result/result.dart';
import '../entities/facility_location.dart';
import '../enums/facility_enums.dart';

/// Patient's current care navigation requirement derived from triage outcome,
/// clinical need, and patient location.
///
/// NOTE: The matcher is a care-navigation suitability engine, NOT a diagnostic engine.
/// It consumes existing TriageResult / NextBestAction and never invents clinical diagnosis.
class PatientCareRequest {
  const PatientCareRequest({
    required this.urgency,
    this.dispositionState,
    this.actionType,
    this.patientLocation,
    this.requiredSpecialtyId,
    this.requiredServiceId,
    this.preferredFacilityType,
    this.requiredScheme,
    this.isEmergencyCareRequired = false,
    this.allowsLimitedEmergency = false,
    this.requiresInpatient = false,
    this.triageReason,
    this.triggeredRuleIds = const [],
  });

  /// Clinical urgency classification (emergency, urgent, soon, routine, or null).
  final TriageUrgency? urgency;

  /// High-level disposition state from TriageResult (05E).
  final TriageDispositionState? dispositionState;

  /// Next best action type from NextBestAction (05F).
  final NextActionType? actionType;

  /// Patient location (coordinates, pincode, district, etc.), if known.
  final FacilityLocation? patientLocation;

  /// Normalized identifier of required clinical specialty (e.g. 'cardiology', 'orthopedics').
  final String? requiredSpecialtyId;

  /// Normalized identifier of required service (e.g. 'ct_scan', 'blood_bank', 'dialysis').
  final String? requiredServiceId;

  /// Preferred level of care / facility type if explicitly selected.
  final FacilityType? preferredFacilityType;

  /// Specific welfare scheme preferred by patient (e.g. 'CMCHIS', 'AB-PMJAY').
  final String? requiredScheme;

  /// Whether immediate life-saving emergency care is indicated.
  final bool isEmergencyCareRequired;

  /// Whether a limited emergency / daytime stabilization facility is acceptable
  /// for this care requirement (e.g. non-critical stabilization or rural initial triage).
  /// When false (default), generic emergency care requires full or standard emergency.
  final bool allowsLimitedEmergency;

  /// Whether inpatient admission capability is explicitly required.
  final bool requiresInpatient;

  /// Explanation or reason passed from triage progression.
  final String? triageReason;

  /// Specific 05B safety rules that triggered (e.g. 'chest_pain_or_pressure').
  final List<String> triggeredRuleIds;

  /// Creates a [PatientCareRequest] directly from a [TriageResult] and optional [NextBestAction].
  factory PatientCareRequest.fromTriage({
    required TriageResult triageResult,
    NextBestAction? nextBestAction,
    FacilityLocation? patientLocation,
    String? requiredSpecialtyId,
    String? requiredServiceId,
    String? requiredScheme,
  }) {
    final isEmergency = triageResult.state == TriageDispositionState.emergency ||
        triageResult.urgency == TriageUrgency.emergency ||
        nextBestAction?.actionType == NextActionType.emergencyCare;

    return PatientCareRequest(
      urgency: triageResult.urgency,
      dispositionState: triageResult.state,
      actionType: nextBestAction?.actionType,
      patientLocation: patientLocation,
      requiredSpecialtyId: requiredSpecialtyId,
      requiredServiceId: requiredServiceId,
      requiredScheme: requiredScheme,
      isEmergencyCareRequired: isEmergency,
      triageReason: triageResult.explanation,
      triggeredRuleIds: triageResult.triggeredRuleIds,
    );
  }
}
