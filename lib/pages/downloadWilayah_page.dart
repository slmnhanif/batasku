import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/db/db_helper.dart';

class DownloadWilayahPage extends StatefulWidget {
  const DownloadWilayahPage({super.key});

  @override
  State<DownloadWilayahPage> createState() => _DownloadWilayahPageState();
}

class _DownloadWilayahPageState extends State<DownloadWilayahPage> {
  String? selectedKabupaten;
  final MapController _mapController = MapController();

  List<String> kabupatenList = [];
  Map<String, List<LatLng>> polygonsMap = {};

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

      // ambil polygon dari JSON
      String polygonJson = region['polygon'] as String;
      List<dynamic> pointsList = jsonDecode(polygonJson);
      List<LatLng> latLngList = pointsList.map<LatLng>((e) {
        // e = [lon, lat]
        return LatLng(e[1], e[0]);
      }).toList();

      polyMap[name] = latLngList;
    }

    setState(() {
      kabupatenList = names;
      polygonsMap = polyMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unduh Nama Wilayah")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(-2.5, 118.0),
              initialZoom: 4.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),

              // tampilkan semua polygon default (hitam)
              PolylineLayer(
                polylines: polygonsMap.entries.map((entry) {
                  bool isSelected = entry.key == selectedKabupaten;
                  return Polyline(
                    points: entry.value,
                    color: isSelected ? Colors.blue : Colors.black,
                    strokeWidth: isSelected ? 4 : 2,
                  );
                }).toList(),
              ),
            ],
          ),

          // Dropdown pilihan kabupaten
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text("Pilih Kabupaten / Kota"),
                  value: selectedKabupaten,
                  items: kabupatenList.map((kab) {
                    return DropdownMenuItem(value: kab, child: Text(kab));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedKabupaten = val;
                      // zoom ke polygon yang dipilih
                      if (val != null && polygonsMap[val]!.isNotEmpty) {
                        var poly = polygonsMap[val]!;
                        var latitudes = poly.map((e) => e.latitude).toList();
                        var longitudes = poly.map((e) => e.longitude).toList();

                        var latCenter = (latitudes.reduce((a, b) => a + b)) /
                            latitudes.length;
                        var lngCenter = (longitudes.reduce((a, b) => a + b)) /
                            longitudes.length;

                        _mapController.move(LatLng(latCenter, lngCenter), 7);
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
