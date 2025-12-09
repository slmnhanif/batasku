import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '/widgets/custom_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String mapType = "satelit";
  bool showFolder = false;

  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(username: "Salman"),
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(-6.200000, 106.816666),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapType == "satelit"
                        ? "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}"
                        : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.app',
                  ),
                ],
              ),
              Positioned(
                top: 40,
                left: 10,
                child: GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: _circleButton(Icons.menu),
                ),
              ),
              Positioned(
                top: 40,
                right: 10,
                child: Column(
                  children: [
                    // LAYER
                    GestureDetector(
                      onTap: () => _openLayerDialog(),
                      child: _circleButton(Icons.layers),
                    ),

                    const SizedBox(height: 12),

                    _circleButton(Icons.folder),
                  ],
                ),
              ),

              Positioned(
                left: 20,
                bottom: 50,
                child: Column(
                  children: [
                    if (showFolder) ...[
                      _expandButton(Icons.location_on),
                      _expandButton(Icons.my_location),
                      _expandButton(Icons.change_history),
                      _expandButton(Icons.image),
                      const SizedBox(height: 8),
                    ],

                    GestureDetector(
                      onTap: () => setState(() => showFolder = !showFolder),
                      child: _circleButton(Icons.work),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => _goToMyLocation(),
                  child: _circleButton(Icons.my_location),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _circleButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 4, offset: Offset(1, 2), color: Colors.black26),
        ],
      ),
      child: Icon(icon, size: 22),
    );
  }

  Widget _expandButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _circleButton(icon),
    );
  }

  void _openLayerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Jenis Tampilan Peta"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text("Satelit"),
              value: "satelit",
              groupValue: mapType,
              onChanged: (val) {
                setState(() => mapType = val!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text("Normal"),
              value: "normal",
              groupValue: mapType,
              onChanged: (val) {
                setState(() => mapType = val!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // GO TO MY LOCATION
  // =====================================================
  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
  }
}
