// lib/pages/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '/widgets/custom_drawer.dart';
import '/db/db_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// -6. 191528, 106.806797
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String mapType = "satelit";
  bool showFolder = false;

  bool isPickingLocation = false;
  bool isPickingBatas = false;
  LatLng? pickedLatLng;

  final MapController _mapController = MapController();

  final List<Marker> _markers = [];
  int _tempIndex = -1;

  Marker? selectedMarker;
  String? selectedName;

  String? selectedMarkerFotoBase64;
  String? selectedMarkerDesc;
  String? selectedMarkerDibuat;
  bool showInputCoord = false;
  String coordType = 'DD'; // 'DD' atau 'DMS'

  final latDdCtrl = TextEditingController();
  final lonDdCtrl = TextEditingController();

  // DMS controller
  final latDegCtrl = TextEditingController();
  final latMinCtrl = TextEditingController();
  final latSecCtrl = TextEditingController();

  final lonDegCtrl = TextEditingController();
  final lonMinCtrl = TextEditingController();
  final lonSecCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMarkersFromDB();
  }

  Future<void> _loadMarkersFromDB() async {
    final db = await DBHelper.instance.database;
    final projectId = DBHelper.instance.activeProjectId;

    if (projectId == null) return;

    final rows = await db.query(
      'marker_kantor_desa',
      where: 'is_delete = 0 AND project_id = ?',
      whereArgs: [projectId],
    );

    final loadedMarkers = rows.map<Marker>((e) {
      final lat = (e['lat'] as num).toDouble();
      final lng = (e['lng'] as num).toDouble();
      final point = LatLng(lat, lng);

      return Marker(
        point: point,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedMarker = Marker(
                point: point,
                child: const Icon(
                  Icons.location_on,
                  size: 36,
                  color: Colors.red,
                ),
              );
              selectedName = e['nama'] as String?;
              selectedMarkerDesc = e['keterangan'] as String?;
              selectedMarkerDibuat = e['dibuat'] as String?;
              selectedMarkerFotoBase64 = e['foto'] as String?;
            });
          },
          child: const Icon(Icons.location_on, color: Colors.red),
        ),
      );
    }).toList();

    setState(() {
      _markers
        ..clear()
        ..addAll(loadedMarkers);

      // reset info card saat ganti project
      selectedMarker = null;
    });
  }

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
                  center: LatLng(-6.200000, 106.816666),
                  zoom: 15,
                  onPositionChanged: (pos, hasGesture) {
                    if ((isPickingLocation || isPickingBatas) &&
                        pos.center != null) {
                      setState(() {
                        pickedLatLng = pos.center;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapType == "satelit"
                        ? "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}"
                        : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.app',
                  ),

                  /// ALL MARKERS
                  MarkerLayer(markers: List<Marker>.from(_markers)),
                ],
              ),
              if ((isPickingLocation || isPickingBatas) && pickedLatLng != null)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // KOORDINAT
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${pickedLatLng!.latitude.toStringAsFixed(6)}, "
                              "${pickedLatLng!.longitude.toStringAsFixed(6)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // ICON STICKY
                          Icon(
                            isPickingBatas
                                ? Icons.change_history
                                : Icons.location_on,
                            size: 48,
                            color: isPickingBatas ? Colors.green : Colors.blue,
                          ),

                          const SizedBox(height: 8),

                          // LENGKAPI DATA
                          ElevatedButton(
                            onPressed: () async {
                              final pt = pickedLatLng!;
                              final isBatasMode = isPickingBatas;

                              setState(() {
                                isPickingLocation = false;
                                isPickingBatas = false;
                                pickedLatLng = null;
                              });

                              if (isBatasMode) {
                                await _showNameDialogAndSaveBatas(pt);
                              } else {
                                await _showNameDialogAndSave(pt);
                              }
                            },
                            child: const Text("Lengkapi Data"),
                          ),

                          const SizedBox(height: 6),

                          // BATAL
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isPickingLocation = false;
                                isPickingBatas = false;
                                pickedLatLng = null;
                              });
                            },
                            child: const Text("Batal"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              /// === INFO MARKER FLOATING BOX ===
              if (selectedMarker != null) _buildInfoCard(),

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
                      GestureDetector(
                        // LOCATION
                        onTap: () {
                          setState(() {
                            isPickingLocation = true;
                            isPickingBatas = false;
                            pickedLatLng = _mapController.center;
                          });
                        },

                        child: _expandButton(Icons.location_on),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => showInputCoord = !showInputCoord);
                        },
                        child: _expandButton(Icons.add_location_sharp),
                      ),
                      GestureDetector(
                        // BATAS / HISTORY
                        onTap: () {
                          setState(() {
                            isPickingBatas = true;
                            isPickingLocation = false;
                            pickedLatLng = _mapController.center;
                          });
                        },

                        child: _expandButton(Icons.change_history),
                      ),
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

              if (showInputCoord)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => showInputCoord = false),
                    child: Container(
                      color: Colors.black45, // overlay
                      child: Center(
                        child: GestureDetector(
                          onTap: () {}, // supaya tap di modal tidak menutup
                          child: Material(
                            elevation: 12,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 280,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// HEADER + TUTUP
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Input Koordinat",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(
                                          () => showInputCoord = false,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// PILIH FORMAT
                                  DropdownButton<String>(
                                    value: coordType,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'DD',
                                        child: Text('Decimal Degree'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'DMS',
                                        child: Text('DMS'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => coordType = v!),
                                  ),

                                  const SizedBox(height: 8),

                                  /// DECIMAL DEGREE
                                  if (coordType == 'DD') ...[
                                    TextField(
                                      controller: latDdCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Latitude',
                                      ),
                                    ),
                                    TextField(
                                      controller: lonDdCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Longitude',
                                      ),
                                    ),
                                  ],

                                  /// DMS
                                  if (coordType == 'DMS') ...[
                                    const Text("Lintang"),
                                    _dmsRow(latDegCtrl, latMinCtrl, latSecCtrl),
                                    const Text("Bujur"),
                                    _dmsRow(lonDegCtrl, lonMinCtrl, lonSecCtrl),
                                  ],

                                  const SizedBox(height: 12),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _addMarkerFromCoordinate,
                                      child: const Text("Tambah Marker"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _dmsRow(
    TextEditingController d,
    TextEditingController m,
    TextEditingController s,
  ) {
    return Row(
      children: [_dmsField(d, '°'), _dmsField(m, "'"), _dmsField(s, '"')],
    );
  }

  Widget _dmsField(TextEditingController c, String hint) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
        ),
      ),
    );
  }

  void _addMarkerFromCoordinate() async {
    try {
      double lat;
      double lng;

      if (coordType == 'DD') {
        lat = double.parse(latDdCtrl.text);
        lng = double.parse(lonDdCtrl.text);
      } else {
        lat = _dmsToDecimal(latDegCtrl.text, latMinCtrl.text, latSecCtrl.text);
        lng = _dmsToDecimal(lonDegCtrl.text, lonMinCtrl.text, lonSecCtrl.text);
      }

      final point = LatLng(lat, lng);

      // MOVE CAMERA
      _mapController.move(point, 17);

      // TAMPILKAN MARKER SEMENTARA
      setState(() {
        _markers.add(
          Marker(
            point: point,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              size: 40,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
        );
        _tempIndex = _markers.length - 1;
        showInputCoord = false;
      });

      // LANJUT KE DIALOG SIMPAN
      // await _showNameDialogAndSave(point);
    } catch (e) {
      debugPrint("Input koordinat error: $e");
    }
  }

  double _dmsToDecimal(String d, String m, String s) {
    return double.parse(d) + double.parse(m) / 60 + double.parse(s) / 3600;
  }

  Widget _buildInfoCard() {
    final marker = selectedMarker!;
    final pos = _mapController.latLngToScreenPoint(marker.point);
    if (pos == null) return const SizedBox();
    return Positioned(
      left: pos.x - 80,
      top: pos.y - 110,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedName ?? "Nama tidak ada",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text("Lat: ${marker.point.latitude.toStringAsFixed(6)}"),
              Text("Lng: ${marker.point.longitude.toStringAsFixed(6)}"),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () => setState(() => selectedMarker = null),
                child: const Text("Tutup"),
              ),
            ],
          ),
        ),
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
        title: const Text('Jenis Tampilan Peta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Satelit'),
              value: 'satelit',
              groupValue: mapType,
              onChanged: (val) {
                setState(() => mapType = val as String);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Normal'),
              value: 'normal',
              groupValue: mapType,
              onChanged: (val) {
                setState(() => mapType = val as String);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _showNameDialogAndSaveBatas(LatLng pt) async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();

    // Auto timestamp
    final dibuatCtrl = TextEditingController(text: DateTime.now().toString());

    File? selectedImage;

    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Simpan Titik Besa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lat: ${pt.latitude.toStringAsFixed(6)}'),
                    Text('Lng: ${pt.longitude.toStringAsFixed(6)}'),
                    const SizedBox(height: 12),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lokasi',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: dibuatCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Dibuat',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        // GALERI
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? file = await picker.pickImage(
                              source: ImageSource.gallery,
                            );

                            if (file != null) {
                              setStateDialog(() {
                                selectedImage = File(file.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.photo),
                          label: const Text("Galeri"),
                        ),

                        const SizedBox(width: 10),

                        // KAMERA
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? file = await picker.pickImage(
                              source: ImageSource.camera,
                              preferredCameraDevice: CameraDevice.rear,
                            );

                            if (file != null) {
                              setStateDialog(() {
                                selectedImage = File(file.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Kamera"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // PREVIEW FOTO
                    if (selectedImage != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImage!,
                            width:
                                MediaQuery.of(context).size.width *
                                0.6, // Lebar menyesuaikan dialog
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showNameDialogAndSave(LatLng pt) async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();

    // Auto timestamp
    final dibuatCtrl = TextEditingController(text: DateTime.now().toString());

    File? selectedImage;

    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Simpan Titik Kantor Desa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lat: ${pt.latitude.toStringAsFixed(6)}'),
                    Text('Lng: ${pt.longitude.toStringAsFixed(6)}'),
                    const SizedBox(height: 12),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lokasi',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: dibuatCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Dibuat',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        // GALERI
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? file = await picker.pickImage(
                              source: ImageSource.gallery,
                            );

                            if (file != null) {
                              setStateDialog(() {
                                selectedImage = File(file.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.photo),
                          label: const Text("Galeri"),
                        ),

                        const SizedBox(width: 10),

                        // KAMERA
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? file = await picker.pickImage(
                              source: ImageSource.camera,
                              preferredCameraDevice: CameraDevice.rear,
                            );

                            if (file != null) {
                              setStateDialog(() {
                                selectedImage = File(file.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Kamera"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // PREVIEW FOTO
                    if (selectedImage != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImage!,
                            width:
                                MediaQuery.of(context).size.width *
                                0.6, // Lebar menyesuaikan dialog
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    // Jika klik SIMPAN
    if (ok == true) {
      final name = nameCtrl.text.trim();
      final desc = descCtrl.text.trim();
      final dibuat = dibuatCtrl.text.trim();

      if (name.isEmpty) return;

      String? fotoBase64;
      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        fotoBase64 = base64Encode(bytes);
      }

      final db = await DBHelper.instance.database;
      final projectId = DBHelper.instance.activeProjectId;

      if (projectId == null) {
        debugPrint("❌ Project aktif belum diset");
        return;
      }

      await db.insert('marker_kantor_desa', {
        'project_id': projectId,
        'nama': name,
        'keterangan': desc,
        'lat': pt.latitude,
        'lng': pt.longitude,
        'dibuat': dibuat,
        'foto': fotoBase64,
        'is_delete': 0,
      });

      setState(() {
        _markers.add(
          Marker(
            point: pt,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMarker = Marker(
                    point: pt,
                    child: const Icon(
                      Icons.location_on,
                      size: 36,
                      color: Colors.red,
                    ),
                  );
                  selectedName = name;
                });
              },
              child: const Icon(Icons.location_on, size: 36, color: Colors.red),
            ),
          ),
        );
      });
    } else {
      // Jika Batal
      if (_tempIndex >= 0 && _tempIndex < _markers.length) {
        setState(() {
          _markers.removeAt(_tempIndex);
          _tempIndex = -1;
        });
      }
    }
  }
}
