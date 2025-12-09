// lib/pages/download_wilayah_page.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/db/db_helper.dart';

enum DrawMode { none, rectangle, pencil }

class DownloadAoiPage extends StatefulWidget {
  const DownloadAoiPage({super.key});

  @override
  State<DownloadAoiPage> createState() => _DownloadAoiPageState();
}

class _DownloadAoiPageState extends State<DownloadAoiPage> {
  final MapController _mapController = MapController();

  // DB data
  List<String> kabupatenList = [];
  Map<String, List<LatLng>> polygonsMap = {};

  DrawMode mode = DrawMode.none;
  String? selectedKabupaten;

  LatLng? rectStart;
  LatLng? rectEnd;

  String? activeHandle;

  List<LatLng> pencilPoints = [];

  Set<String> highlighted = {};

  @override
  void initState() {
    super.initState();
    _loadRegionsFromDB();
  }

  Future<void> _loadRegionsFromDB() async {
    final db = await DBHelper.instance.database;
    final regions = await db.query('regions');
    List<String> names = [];
    Map<String, List<LatLng>> polyMap = {};

    for (var region in regions) {
      String name = region['name'] as String;
      names.add(name);

      String polygonJson = region['polygon'] as String;
      List<dynamic> pointsList = jsonDecode(polygonJson);
      List<LatLng> latLngList = pointsList.map<LatLng>((e) {
        return LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble());
      }).toList();

      polyMap[name] = latLngList;
    }

    setState(() {
      kabupatenList = names;
      polygonsMap = polyMap;
    });
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    final x = point.longitude;
    final y = point.latitude;
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  int _orientation(LatLng a, LatLng b, LatLng c) {
    double val = (b.latitude - a.latitude) * (c.longitude - b.longitude) -
        (b.longitude - a.longitude) * (c.latitude - b.latitude);
    if (val.abs() < 1e-12) return 0;
    return (val > 0) ? 1 : 2;
  }

  bool _onSegment(LatLng a, LatLng b, LatLng c) {
    return (c.longitude <= max(a.longitude, b.longitude) &&
        c.longitude >= min(a.longitude, b.longitude) &&
        c.latitude <= max(a.latitude, b.latitude) &&
        c.latitude >= min(a.latitude, b.latitude));
  }

  bool _segmentsIntersect(LatLng p1, LatLng q1, LatLng p2, LatLng q2) {
    int o1 = _orientation(p1, q1, p2);
    int o2 = _orientation(p1, q1, q2);
    int o3 = _orientation(p2, q2, p1);
    int o4 = _orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;
    if (o1 == 0 && _onSegment(p1, q1, p2)) return true;
    if (o2 == 0 && _onSegment(p1, q1, q2)) return true;
    if (o3 == 0 && _onSegment(p2, q2, p1)) return true;
    if (o4 == 0 && _onSegment(p2, q2, q1)) return true;
    return false;
  }

  bool _polylineIntersectsPolygon(List<LatLng> line, List<LatLng> polygon) {
    for (int i = 0; i < line.length - 1; i++) {
      final a = line[i];
      final b = line[i + 1];
      for (int j = 0; j < polygon.length - 1; j++) {
        final c = polygon[j];
        final d = polygon[j + 1];
        if (_segmentsIntersect(a, b, c, d)) return true;
      }
      final mid = LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );
      if (_pointInPolygon(mid, polygon)) return true;
    }
    return false;
  }

  bool _polygonIntersectsPolygon(List<LatLng> polyA, List<LatLng> polyB) {
    if (_polylineIntersectsPolygon(polyA, polyB)) return true;
    if (_polylineIntersectsPolygon(polyB, polyA)) return true;
    if (_pointInPolygon(polyA[0], polyB)) return true;
    if (_pointInPolygon(polyB[0], polyA)) return true;
    return false;
  }

  List<LatLng> _rectToPolygon(LatLng a, LatLng b) {
    final south = min(a.latitude, b.latitude);
    final north = max(a.latitude, b.latitude);
    final west = min(a.longitude, b.longitude);
    final east = max(a.longitude, b.longitude);
    return [
      LatLng(south, west),
      LatLng(south, east),
      LatLng(north, east),
      LatLng(north, west),
      LatLng(south, west),
    ];
  }

  void _evaluateHighlights() {
    Set<String> newHighlighted = {};

    List<LatLng>? selRectPoly;
    if (rectStart != null && rectEnd != null) {
      selRectPoly = _rectToPolygon(rectStart!, rectEnd!);
    }

    for (final entry in polygonsMap.entries) {
      final name = entry.key;
      final poly = entry.value;

      bool intersects = false;

      if (mode == DrawMode.pencil && pencilPoints.length >= 2) {
        intersects = _polylineIntersectsPolygon(pencilPoints, poly) ||
            pencilPoints.any((p) => _pointInPolygon(p, poly));
      }

      if (!intersects && selRectPoly != null) {
        intersects = _polygonIntersectsPolygon(selRectPoly, poly);
      }

      if (intersects) newHighlighted.add(name);
    }

    setState(() {
      highlighted = newHighlighted;
    });
  }

  void _clearSelection() {
    setState(() {
      rectStart = null;
      rectEnd = null;
      pencilPoints = [];
      highlighted.clear();
      mode = DrawMode.none;
    });
  }

  Offset? _dragStartOffset;
  Offset? _lastOffset;

  LatLng? _offsetToLatLng(Offset offset) {
    try {
      final screenPoint = CustomPoint(offset.dx, offset.dy);
      final latlng = _mapController.pointToLatLng(screenPoint);
      return latlng;
    } catch (e) {
      return null;
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (mode == DrawMode.none) return;
    _dragStartOffset = details.localPosition;
    _lastOffset = details.localPosition;

    final startLatLng = _offsetToLatLng(_dragStartOffset!);
    if (startLatLng == null) return;

    if (mode == DrawMode.rectangle) {
      if (rectStart != null && rectEnd != null) {
        final corners = _rectToPolygon(rectStart!, rectEnd!);
        for (int i = 0; i < 4; i++) {
          final corner = corners[i];
          final cornerOffset = _mapController.latLngToScreenPoint(corner);
          final dx = (cornerOffset.x - _dragStartOffset!.dx).abs();
          final dy = (cornerOffset.y - _dragStartOffset!.dy).abs();
          if (dx <= 20 && dy <= 20) {
            activeHandle = ['sw', 'se', 'ne', 'nw'][i];
            break;
          }
        }
        if (activeHandle == null) {
          final rectPoly = _rectToPolygon(rectStart!, rectEnd!);
          if (_pointInPolygon(startLatLng, rectPoly)) activeHandle = 'move';
        }
      } else {
        rectStart = startLatLng;
        rectEnd = startLatLng;
      }
      _evaluateHighlights();
    } else if (mode == DrawMode.pencil) {
      pencilPoints = [startLatLng];
      _evaluateHighlights();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (mode == DrawMode.none) return;
    _lastOffset = details.localPosition;
    final posLatLng = _offsetToLatLng(details.localPosition);
    if (posLatLng == null) return;

    if (mode == DrawMode.rectangle) {
      if (activeHandle == null) {
        rectEnd = posLatLng;
      } else if (activeHandle == 'move') {
        final prevLatLng = _offsetToLatLng(_dragStartOffset!);
        if (prevLatLng == null) return;
        final dLat = posLatLng.latitude - prevLatLng.latitude;
        final dLng = posLatLng.longitude - prevLatLng.longitude;
        rectStart = LatLng(
          rectStart!.latitude + dLat,
          rectStart!.longitude + dLng,
        );
        rectEnd = LatLng(rectEnd!.latitude + dLat, rectEnd!.longitude + dLng);
        _dragStartOffset = details.localPosition;
      } else {
        switch (activeHandle) {
          case 'sw':
            rectStart = LatLng(posLatLng.latitude, posLatLng.longitude);
            break;
          case 'se':
            rectStart = LatLng(rectStart!.latitude, rectStart!.longitude);
            rectEnd = LatLng(posLatLng.latitude, posLatLng.longitude);
            break;
          case 'ne':
            rectEnd = LatLng(posLatLng.latitude, posLatLng.longitude);
            break;
          case 'nw':
            rectStart = LatLng(rectStart!.latitude, posLatLng.longitude);
            rectEnd = LatLng(posLatLng.latitude, rectEnd!.longitude);
            break;
          default:
            break;
        }
      }
      _evaluateHighlights();
    } else if (mode == DrawMode.pencil) {
      pencilPoints.add(posLatLng);
      _evaluateHighlights();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    activeHandle = null;
    _dragStartOffset = null;
    _lastOffset = null;

    if (rectStart != null && rectEnd != null) {
      final dLat = (rectStart!.latitude - rectEnd!.latitude).abs();
      final dLng = (rectStart!.longitude - rectEnd!.longitude).abs();
      if (dLat < 1e-6 && dLng < 1e-6) {
        rectStart = null;
        rectEnd = null;
      }
    }

    setState(() {});
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconButton(
            icon: Icons.crop_square,
            active: mode == DrawMode.rectangle,
            onTap: () {
              setState(() {
                if (mode == DrawMode.rectangle) {
                  mode = DrawMode.none;
                } else {
                  mode = DrawMode.rectangle;
                  pencilPoints = [];
                  _createDefaultRectangle();
                }
              });
            },
            tooltip: 'Rectangle (drag/resize)',
          ),
          const SizedBox(height: 8),
          _iconButton(
            icon: Icons.edit,
            active: mode == DrawMode.pencil,
            onTap: () {
              setState(() {
                if (mode == DrawMode.pencil) {
                  mode = DrawMode.none;
                } else {
                  mode = DrawMode.pencil;
                  rectStart = null;
                  rectEnd = null;
                  pencilPoints = [];
                }
              });
            },
            tooltip: 'Pencil (draw realtime)',
          ),
          const SizedBox(height: 8),
          _iconButton(
            icon: Icons.clear,
            active: false,
            onTap: _clearSelection,
            tooltip: 'Clear shapes',
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: Icon(icon, color: active ? Colors.white : Colors.black87),
      ),
    );
  }

  List<Polygon> _buildPolygons() {
    final List<Polygon> out = [];
    polygonsMap.forEach((name, poly) {
      final isHighlighted = highlighted.contains(name);
      out.add(
        Polygon(
          points: poly,
          color: isHighlighted
              ? Colors.blue.withOpacity(0.35)
              : Colors.black.withOpacity(0.08),
          borderColor: isHighlighted ? Colors.blue : Colors.black,
          borderStrokeWidth: isHighlighted ? 2.5 : 1.2,
        ),
      );
    });
    return out;
  }

  List<Polygon> _buildSelectionPolygons() {
    final List<Polygon> out = [];
    if (rectStart != null && rectEnd != null) {
      final rectPoly = _rectToPolygon(rectStart!, rectEnd!);
      out.add(
        Polygon(
          points: rectPoly,
          color: Colors.transparent,
          borderColor: Colors.red,
          borderStrokeWidth: 2.0,
        ),
      );
    }
    if (pencilPoints.isNotEmpty) {
      out.add(
        Polygon(
          points: pencilPoints,
          color: Colors.transparent,
          borderColor: Colors.green,
          borderStrokeWidth: 2.0,
        ),
      );
    }
    return out;
  }

  void _createDefaultRectangle() {
    final center = _mapController.center;

    const delta = 0.05;

    rectStart = LatLng(center.latitude - delta, center.longitude - delta);
    rectEnd = LatLng(center.latitude + delta, center.longitude + delta);

    setState(() {});
    _evaluateHighlights();
  }

  List<Marker> _buildHandles() {
    final List<Marker> out = [];
    if (rectStart == null || rectEnd == null) return out;
    final rectPoly = _rectToPolygon(rectStart!, rectEnd!);
    // corners: sw,se,ne,nw
    final corners = [rectPoly[0], rectPoly[1], rectPoly[2], rectPoly[3]];
    for (int i = 0; i < corners.length; i++) {
      out.add(
        Marker(
          width: 20,
          height: 20,
          point: corners[i],
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black38),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.drag_handle, size: 12),
          ),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unduh AOI")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              interactiveFlags: InteractiveFlag.all,
              center: LatLng(-2.5, 118.0),
              zoom: 4.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),
              PolygonLayer(polygons: _buildPolygons()),
              PolygonLayer(polygons: _buildSelectionPolygons()),
              MarkerLayer(markers: _buildHandles()),
            ],
          ),
          _buildTopBar(),
          if (mode != DrawMode.none)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) => _onPanStart(details),
                onPanUpdate: (details) => _onPanUpdate(details),
                onPanEnd: (details) => _onPanEnd(details),
              ),
            ),
        ],
      ),
    );
  }
}
