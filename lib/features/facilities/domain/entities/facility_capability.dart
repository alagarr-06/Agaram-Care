// Task 08 - Agaram Care Facility Operational Capability Entity.
library;

/// Operational capabilities and service availability for a healthcare facility.
///
/// CRITICAL ARCHITECTURAL PRINCIPLE:
/// UNKNOWN != NO.
///
/// Where current or live information is unavailable, fields MUST remain `null`
/// rather than defaulting to `false`, `0`, or "unavailable".
///
/// Agaram Care does NOT fabricate live operational metrics (bed counts, live ICU
/// occupancy, pharmacy inventory).
class FacilityCapability {
  const FacilityCapability({
    this.inpatientAvailable,
    this.icuAvailable,
    this.teleconsultAvailable,
    this.pharmacyAvailable,
    this.bloodBankAvailable,
    this.ambulanceAvailable,
    this.burnUnitAvailable,
    this.neonatalIcuAvailable,
    this.ventilatorAvailable,
    this.approxTotalBeds,
  });

  /// Inpatient bed ward capability. `null` means unknown/unverified.
  final bool? inpatientAvailable;

  /// Intensive Care Unit capability. `null` means unknown/unverified.
  final bool? icuAvailable;

  /// Telemedicine / remote consultation capability. `null` means unknown/unverified.
  final bool? teleconsultAvailable;

  /// Pharmacy or dispensary available on-premises. `null` means unknown/unverified.
  final bool? pharmacyAvailable;

  /// Blood bank or blood storage facility available. `null` means unknown/unverified.
  final bool? bloodBankAvailable;

  /// Dedicated ambulance dispatch service available. `null` means unknown/unverified.
  final bool? ambulanceAvailable;

  /// Specialized burn care unit available. `null` means unknown/unverified.
  final bool? burnUnitAvailable;

  /// Neonatal Intensive Care Unit (NICU). `null` means unknown/unverified.
  final bool? neonatalIcuAvailable;

  /// Ventilator / mechanical life-support capability. `null` means unknown/unverified.
  final bool? ventilatorAvailable;

  /// Approximate total registered capacity beds from registry, if known.
  /// NOTE: This is nominal registered capacity, NEVER live unoccupied bed counts.
  final int? approxTotalBeds;

  factory FacilityCapability.fromJson(Map<String, dynamic> json) {
    return FacilityCapability(
      inpatientAvailable: json['inpatientAvailable'] as bool?,
      icuAvailable: json['icuAvailable'] as bool?,
      teleconsultAvailable: json['teleconsultAvailable'] as bool?,
      pharmacyAvailable: json['pharmacyAvailable'] as bool?,
      bloodBankAvailable: json['bloodBankAvailable'] as bool?,
      ambulanceAvailable: json['ambulanceAvailable'] as bool?,
      burnUnitAvailable: json['burnUnitAvailable'] as bool?,
      neonatalIcuAvailable: json['neonatalIcuAvailable'] as bool?,
      ventilatorAvailable: json['ventilatorAvailable'] as bool?,
      approxTotalBeds: json['approxTotalBeds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (inpatientAvailable != null) 'inpatientAvailable': inpatientAvailable,
    if (icuAvailable != null) 'icuAvailable': icuAvailable,
    if (teleconsultAvailable != null) 'teleconsultAvailable': teleconsultAvailable,
    if (pharmacyAvailable != null) 'pharmacyAvailable': pharmacyAvailable,
    if (bloodBankAvailable != null) 'bloodBankAvailable': bloodBankAvailable,
    if (ambulanceAvailable != null) 'ambulanceAvailable': ambulanceAvailable,
    if (burnUnitAvailable != null) 'burnUnitAvailable': burnUnitAvailable,
    if (neonatalIcuAvailable != null) 'neonatalIcuAvailable': neonatalIcuAvailable,
    if (ventilatorAvailable != null) 'ventilatorAvailable': ventilatorAvailable,
    if (approxTotalBeds != null) 'approxTotalBeds': approxTotalBeds,
  };
}
