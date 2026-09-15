// Task 10 - Agaram Care Facility UI & Map Screen.
//
// The central healthcare facility discovery and navigation screen.
//
// INVARIANTS:
// - Consumes Task 09 FacilityMatchingEngine results without altering weights or logic.
// - Supports both List View and interactive Map View.
// - UNKNOWN != NO: missing fields displayed as "Not verified".
// - Zero fake facilities or coordinates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_state.dart';
import '../domain/facilities.dart';
import 'providers/facilities_provider.dart';
import 'widgets/facility_card.dart';
import 'widgets/facility_map_view.dart';

class FacilitiesScreen extends ConsumerStatefulWidget {
  const FacilitiesScreen({
    super.key,
    this.initialCareRequest,
  });

  final PatientCareRequest? initialCareRequest;

  @override
  ConsumerState<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends ConsumerState<FacilitiesScreen> {
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCareRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeCareRequestProvider.notifier).state = widget.initialCareRequest;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _launchDirections(BuildContext context, FacilityMatchResult result) {
    final loc = result.facility.location;
    if (!loc.hasCoordinates) return;

    final lat = loc.latitude!;
    final lon = loc.longitude!;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions, color: Colors.teal),
            SizedBox(width: 8),
            Text('Get Directions', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.facility.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('GPS Coordinates: $lat, $lon'),
            const SizedBox(height: 4),
            Text(
              'Destination URL:\n$url',
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // theme
    final locale = ref.watch(selectedLocaleProvider);
    final isTamil = locale.languageCode == 'ta';
    final isHindi = locale.languageCode == 'hi';

    String text({
      required String en,
      required String ta,
      required String hi,
    }) {
      if (isTamil) return ta;
      if (isHindi) return hi;
      return en;
    }

    final matchedResultsAsync = ref.watch(matchedFacilitiesProvider);
    final filterState = ref.watch(facilityFilterProvider);
    final activeRequest = ref.watch(activeCareRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text(
            en: 'Healthcare Facilities',
            ta: 'மருத்துவமனைகள் & மையங்கள்',
            hi: 'स्वास्थ्य सुविधाएं',
          ),
        ),
        actions: [
          // View Switcher (List <-> Map)
          IconButton(
            tooltip: _isMapView ? text(en: 'List View', ta: 'பட்டியல்', hi: 'सूची') : text(en: 'Map View', ta: 'வரைபடம்', hi: 'मानचित्र'),
            icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Care Context Banner (if coming from Triage)
            if (activeRequest != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: activeRequest.isEmergencyCareRequired
                    ? Colors.red.shade50
                    : Colors.teal.shade50,
                child: Row(
                  children: [
                    Icon(
                      activeRequest.isEmergencyCareRequired
                          ? Icons.warning_amber_rounded
                          : Icons.healing_outlined,
                      color: activeRequest.isEmergencyCareRequired
                          ? Colors.red
                          : Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeRequest.isEmergencyCareRequired
                                ? text(
                                    en: 'Urgent Care Need Active',
                                    ta: 'அவசர சிகிச்சை தேவை',
                                    hi: 'आपातकालीन देखभाल आवश्यकता',
                                  )
                                : text(
                                    en: 'Triage Recommendation Applied',
                                    ta: 'பரிசோதனை பரிந்துரை பயன்படுத்தப்பட்டது',
                                    hi: 'ट्राइएज सिफारिश लागू की गई',
                                  ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: activeRequest.isEmergencyCareRequired
                                  ? Colors.red.shade900
                                  : Colors.teal.shade900,
                            ),
                          ),
                          if (activeRequest.triageReason != null)
                            Text(
                              activeRequest.triageReason!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        ref.read(activeCareRequestProvider.notifier).state = null;
                      },
                      child: Text(text(en: 'Clear', ta: 'நீக்கு', hi: 'हटाएं')),
                    ),
                  ],
                ),
              ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(facilityFilterProvider.notifier).state =
                      filterState.copyWith(searchQuery: val);
                },
                decoration: InputDecoration(
                  hintText: text(
                    en: 'Search facility, district, or PIN...',
                    ta: 'மருத்துவமனை, மாவட்டம் அல்லது பின்கோட்...',
                    hi: 'सुविधा, जिला या पिन खोजें...',
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(facilityFilterProvider.notifier).state =
                                filterState.copyWith(searchQuery: '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(text(en: 'Emergency', ta: 'அவசரம்', hi: 'आपातकाल')),
                    selected: filterState.emergencyOnly,
                    onSelected: (val) {
                      ref.read(facilityFilterProvider.notifier).state =
                          filterState.copyWith(emergencyOnly: val);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(text(en: 'Government', ta: 'அரசு', hi: 'सरकारी')),
                    selected: filterState.governmentOnly,
                    onSelected: (val) {
                      ref.read(facilityFilterProvider.notifier).state =
                          filterState.copyWith(governmentOnly: val);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(text(en: 'With GPS Map', ta: 'வரைபடத்துடன்', hi: 'मानचित्र सहित')),
                    selected: filterState.withCoordinatesOnly,
                    onSelected: (val) {
                      ref.read(facilityFilterProvider.notifier).state =
                          filterState.copyWith(withCoordinatesOnly: val);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 12),

            // Content: List or Map View
            Expanded(
              child: matchedResultsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '${text(en: 'Error loading facilities:', ta: 'பிழை:', hi: 'त्रुटि:')} \$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_hospital_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            text(
                              en: 'No facilities match the current criteria',
                              ta: 'பொருத்தமான மருத்துவமனைகள் எதுவும் கிடைக்கவில்லை',
                              hi: 'वर्तमान मानदंडों से मेल खाने वाली कोई सुविधा नहीं है',
                            ),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_isMapView) {
                    return FacilityMapView(
                      facilities: results,
                      userLocation: activeRequest?.patientLocation,
                      onGetDirections: (res) => _launchDirections(context, res),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return FacilityCard(
                        matchResult: item,
                        onGetDirections: () => _launchDirections(context, item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
