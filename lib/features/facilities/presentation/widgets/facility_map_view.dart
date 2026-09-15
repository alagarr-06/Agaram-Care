// Task 10 - Facility Interactive Map Component.
//
// Renders an interactive map plotting real healthcare facilities using WGS-84 coordinates.
//
// CRITICAL INVARIANTS:
// - Zero fake coordinates or markers: Only facilities with verified latitude/longitude are plotted.
// - Supports pan, pinch-to-zoom, dynamic viewport framing, and cluster/pin tapping.
// - Marker clustering: Nearby facilities group into count badges when zoomed out.
// - Clustering is purely visual: underlying Task 09 ranking, ordering, and evidence are strictly preserved.
// - Self-contained canvas/painter.
// - Works flawlessly across Windows, Web, and Android without external API keys or SDK crashes.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_state.dart';
import '../../domain/facilities.dart';
import 'facility_detail_sheet.dart';

/// Represents either an individual facility or a visual cluster of facilities.
class MapMarkerCluster {
  const MapMarkerCluster({
    required this.latitude,
    required this.longitude,
    required this.items,
  });

  final double latitude;
  final double longitude;
  final List<FacilityMatchResult> items;

  bool get isCluster => items.length > 1;
  int get count => items.length;
  FacilityMatchResult get single => items.first;

  /// Whether any facility in this cluster has confirmed emergency capability.
  bool get hasEmergency {
    return items.any((m) =>
        m.facility.emergencyCapability == EmergencyCapability.fullEmergency ||
        m.facility.emergencyCapability == EmergencyCapability.emergencyAvailable);
  }
}

class FacilityMapView extends ConsumerStatefulWidget {
  const FacilityMapView({
    super.key,
    required this.facilities,
    this.userLocation,
    this.onFacilitySelected,
    this.onGetDirections,
  });

  final List<FacilityMatchResult> facilities;
  final FacilityLocation? userLocation;
  final ValueChanged<FacilityMatchResult>? onFacilitySelected;
  final ValueChanged<FacilityMatchResult>? onGetDirections;

  @override
  ConsumerState<FacilityMapView> createState() => _FacilityMapViewState();
}

class _FacilityMapViewState extends ConsumerState<FacilityMapView> {
  // Center coordinates & Zoom level
  double _centerLat = 10.805;
  double _centerLon = 78.289;
  double _zoom = 7.0; // Zoom level 6.0 (statewide) to 16.0 (street)

  bool _hasFittedInitialViewport = false;
  FacilityMatchResult? _selectedFacility;

  @override
  void initState() {
    super.initState();
    _recalculateInitialBounds();
  }

  @override
  void didUpdateWidget(FacilityMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.facilities != widget.facilities) {
      _hasFittedInitialViewport = false;
      _recalculateInitialBounds();
    }
  }

  /// Calculates center and zoom to fit the actual latitude/longitude bounding box
  /// of facilities currently being displayed.
  void _recalculateInitialBounds({Size? viewportSize}) {
    final withCoords = widget.facilities
        .where((f) => f.facility.location.hasCoordinates)
        .toList();

    if (withCoords.isEmpty) {
      // Safe fallback when no facilities have coordinates (e.g. statewide TN center)
      _centerLat = 10.805;
      _centerLon = 78.289;
      _zoom = 7.0;
      return;
    }

    if (withCoords.length == 1) {
      // Single facility: center on it at a clear district/street level
      _centerLat = withCoords.first.facility.location.latitude!;
      _centerLon = withCoords.first.facility.location.longitude!;
      _zoom = 13.0;
      return;
    }

    // Multiple facilities: compute bounding box
    var minLat = 90.0;
    var maxLat = -90.0;
    var minLon = 180.0;
    var maxLon = -180.0;

    for (final item in withCoords) {
      final lat = item.facility.location.latitude!;
      final lon = item.facility.location.longitude!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;
    }

    _centerLat = (minLat + maxLat) / 2.0;
    _centerLon = (minLon + maxLon) / 2.0;

    // Use viewport dimensions if available, otherwise default standard mobile size (360x640)
    final width = viewportSize?.width ?? 360.0;
    final height = viewportSize?.height ?? 640.0;

    // Available screen space with comfortable padding for top status bar and bottom FABs
    final availW = math.max(width - 48.0, 100.0);
    final availH = math.max(height - 120.0, 100.0);

    final deltaLon = math.max(maxLon - minLon, 0.005);

    // Mercator projected delta-y
    double latToMercatorY(double lat) {
      final sinY = math.sin(lat * math.pi / 180.0).clamp(-0.9999, 0.9999);
      return 0.5 - math.log((1.0 + sinY) / (1.0 - sinY)) / (4.0 * math.pi);
    }

    final deltaY = math.max(latToMercatorY(minLat) - latToMercatorY(maxLat), 0.00005);

    final zoomX = math.log(availW * 360.0 / (deltaLon * 256.0)) / math.ln2;
    final zoomY = math.log(availH / (deltaY * 256.0)) / math.ln2;

    final fittedZoom = math.min(zoomX, zoomY);

    // Statewide view of Tamil Nadu fits at ~6.5 to 7.5.
    // For close facilities or single districts, avoid extreme over-zooming on initial load.
    _zoom = fittedZoom.clamp(6.5, 13.0);
  }

  /// Groups facilities into spatial grid clusters based on the current zoom level.
  /// Purely visual grouping; preserves underlying Task 09 models, scoring, and data.
  List<MapMarkerCluster> _computeClusters(List<FacilityMatchResult> plotted) {
    if (plotted.isEmpty) return const [];
    // At maximum zoom levels (>= 16.0), separation is complete; show individual pins
    if (_zoom >= 16.0) {
      return plotted
          .map((m) => MapMarkerCluster(
                latitude: m.facility.location.latitude!,
                longitude: m.facility.location.longitude!,
                items: [m],
              ))
          .toList();
    }

    // Determine grid cell size in degrees based on zoom level
    // A 56-pixel visual cluster threshold on screen
    const clusterPixelRadius = 56.0;
    final scale = 256.0 * math.pow(2, _zoom);
    final gridDeg = clusterPixelRadius * 360.0 / scale;

    final cellMap = <int, List<FacilityMatchResult>>{};

    for (final match in plotted) {
      final lat = match.facility.location.latitude!;
      final lon = match.facility.location.longitude!;

      final gx = (lon / gridDeg).floor();
      final gy = (lat / gridDeg).floor();
      // Combine 32-bit hashes into unique integer key
      final key = (gx * 73856093) ^ (gy * 19349663);

      cellMap.putIfAbsent(key, () => []).add(match);
    }

    final result = <MapMarkerCluster>[];
    for (final group in cellMap.values) {
      if (group.length == 1) {
        result.add(MapMarkerCluster(
          latitude: group.first.facility.location.latitude!,
          longitude: group.first.facility.location.longitude!,
          items: group,
        ));
      } else {
        var sumLat = 0.0;
        var sumLon = 0.0;
        for (final m in group) {
          sumLat += m.facility.location.latitude!;
          sumLon += m.facility.location.longitude!;
        }
        result.add(MapMarkerCluster(
          latitude: sumLat / group.length,
          longitude: sumLon / group.length,
          items: group,
        ));
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
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

    final plotted = widget.facilities
        .where((item) => item.facility.location.hasCoordinates)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Auto-fit initial viewport on first layout with real dimensions
        if (!_hasFittedInitialViewport && width > 0 && height > 0) {
          _hasFittedInitialViewport = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _recalculateInitialBounds(viewportSize: Size(width, height));
              });
            }
          });
        }

        // Generate clusters for the current viewport & zoom
        final clusters = _computeClusters(plotted);

        return Stack(
          children: [
            // Interactive Pan/Zoom Canvas
            GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  // Pan
                  final scaleFactor = math.pow(2, _zoom);
                  final deltaLat = -details.focalPointDelta.dy * (360.0 / (256.0 * scaleFactor));
                  final deltaLon = details.focalPointDelta.dx * (360.0 / (256.0 * scaleFactor));
                  _centerLat = (_centerLat + deltaLat).clamp(7.5, 14.5);
                  _centerLon = (_centerLon + deltaLon).clamp(75.5, 81.5);

                  // Zoom
                  if (details.scale != 1.0) {
                    _zoom = (_zoom + math.log(details.scale) / math.ln2 * 0.05).clamp(6.0, 16.0);
                  }
                });
              },
              child: CustomPaint(
                size: Size(width, height),
                painter: _MapCanvasPainter(
                  centerLat: _centerLat,
                  centerLon: _centerLon,
                  zoom: _zoom,
                ),
              ),
            ),

            // Render Map Markers & Clusters
            ...clusters.map((cluster) {
              final pos = _latLonToScreen(
                cluster.latitude,
                cluster.longitude,
                width,
                height,
              );

              // Skip markers completely outside the viewport with generous buffer
              if (pos.dx < -40 || pos.dx > width + 40 || pos.dy < -40 || pos.dy > height + 40) {
                return const SizedBox.shrink();
              }

              if (cluster.isCluster) {
                // RENDER CLUSTER BADGE
                return Positioned(
                  left: pos.dx - 22,
                  top: pos.dy - 22,
                  child: GestureDetector(
                    onTap: () {
                      // Tapping a cluster zooms in toward that cluster
                      setState(() {
                        _centerLat = cluster.latitude;
                        _centerLon = cluster.longitude;
                        _zoom = (_zoom + 1.8).clamp(6.0, 16.0);
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cluster.hasEmergency
                            ? const Color(0xFFC62828)
                            : const Color(0xFF00695C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cluster.count > 999 ? '${(cluster.count / 1000).toStringAsFixed(1)}k' : '${cluster.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // RENDER INDIVIDUAL FACILITY PIN
                final match = cluster.single;
                final isSelected = _selectedFacility?.facility.id == match.facility.id;
                final isEmergency = match.facility.emergencyCapability == EmergencyCapability.fullEmergency ||
                    match.facility.emergencyCapability == EmergencyCapability.emergencyAvailable;

                return Positioned(
                  left: pos.dx - 18,
                  top: pos.dy - 36,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFacility = match;
                      });
                      widget.onFacilitySelected?.call(match);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black
                                  : (isEmergency ? Colors.red : Colors.teal),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isEmergency ? Icons.emergency : Icons.local_hospital,
                              color: Colors.white,
                              size: isSelected ? 18 : 14,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(8, 6),
                            painter: _TrianglePainter(
                              color: isSelected
                                  ? Colors.black
                                  : (isEmergency ? Colors.red : Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }),

            // Top Status Bar: Count of plotted vs unplotted
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text(
                          en: '${plotted.length} facilities on map (${widget.facilities.length - plotted.length} without GPS coordinates)',
                          ta: '${plotted.length} மருத்துவமனைகள் வரைபடத்தில் உள்ளன',
                          hi: 'मानचित्र पर ${plotted.length} सुविधाएं उपलब्ध हैं',
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zoom In / Out & Recenter Controls
            Positioned(
              right: 16,
              bottom: _selectedFacility != null ? 180 : 20,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_in',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom + 1.0).clamp(6.0, 16.0);
                      });
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_out',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom - 1.0).clamp(6.0, 16.0);
                      });
                    },
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_recenter',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                    tooltip: text(
                      en: 'Fit Tamil Nadu extent',
                      ta: 'முழு வரைபடத்தை பொருத்து',
                      hi: 'मानचित्र को फिट करें',
                    ),
                    onPressed: () {
                      setState(() {
                        _recalculateInitialBounds(viewportSize: Size(width, height));
                      });
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

            // Bottom Selected Facility Popup Card
            if (_selectedFacility != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedFacility!.facility.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _selectedFacility = null;
                                });
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedFacility!.facility.location.district}${_selectedFacility!.formattedDistance != null ? " • ${_selectedFacility!.formattedDistance}" : ""}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => FacilityDetailSheet(
                                      facility: _selectedFacility!.facility,
                                      distanceKm: _selectedFacility!.distanceKm,
                                      onGetDirections: () => widget.onGetDirections?.call(_selectedFacility!),
                                    ),
                                  );
                                },
                                child: Text(text(en: 'Details', ta: 'விவரங்கள்', hi: 'विवरण')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => widget.onGetDirections?.call(_selectedFacility!),
                                icon: const Icon(Icons.directions, size: 16),
                                label: Text(text(en: 'Directions', ta: 'வழிகாட்டுதல்', hi: 'दिशा')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Offset _latLonToScreen(double lat, double lon, double width, double height) {
    final scale = 256.0 * math.pow(2, _zoom);
    final centerPixelX = ((_centerLon + 180.0) / 360.0) * scale;
    final centerSinY = math.sin(_centerLat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final centerPixelY = (0.5 - math.log((1.0 + centerSinY) / (1.0 - centerSinY)) / (4.0 * math.pi)) * scale;

    final targetPixelX = ((lon + 180.0) / 360.0) * scale;
    final targetSinY = math.sin(lat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    final targetPixelY = (0.5 - math.log((1.0 + targetSinY) / (1.0 - targetSinY)) / (4.0 * math.pi)) * scale;

    final screenX = (width / 2.0) + (targetPixelX - centerPixelX);
    final screenY = (height / 2.0) + (targetPixelY - centerPixelY);

    return Offset(screenX, screenY);
  }
}

class _MapCanvasPainter extends CustomPainter {
  _MapCanvasPainter({
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
  });

  final double centerLat;
  final double centerLon;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw smooth map background
    final bgPaint = Paint()..color = const Color(0xFFE8ECEF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw subtle latitude/longitude geographic grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    for (var x = 0.0; x < size.width; x += 60.0) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 60.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Draw Tamil Nadu region indication watermark
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Tamil Nadu Healthcare Registry Map',
        style: TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(16, size.height - 28));
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.centerLat != centerLat ||
        oldDelegate.centerLon != centerLon ||
        oldDelegate.zoom != zoom;
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
