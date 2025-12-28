import 'package:flutter/material.dart';
import '/pages/downloadWilayah_page.dart';
import '/pages/downloadaOI_page.dart';
import '/pages/projectList_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CustomDrawer extends StatelessWidget {
  final String username;

  const CustomDrawer({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER
          Container(
            height: 180,
            color: Colors.blue,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            child: Stack(
              children: [
                /// INFO USER
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 36, color: Colors.blue),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Hai, $username",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                /// STATUS ONLINE / OFFLINE (POJOK KANAN ATAS)
                Positioned(
                  top: 0,
                  right: 0,
                  child: StreamBuilder<List<ConnectivityResult>>(
                    stream: Connectivity().onConnectivityChanged,
                    builder: (context, snapshot) {
                      final hasConnection =
                          snapshot.hasData &&
                          snapshot.data!.any(
                            (e) => e != ConnectivityResult.none,
                          );

                      return Row(
                        children: [
                          Icon(
                            hasConnection ? Icons.wifi : Icons.wifi_off,
                            color: hasConnection
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasConnection ? "Online" : "Offline",
                            style: TextStyle(
                              color: hasConnection
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: const Text("Pengaturan"),
            children: [
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Satuan Lokasi"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text("Satuan Jarak"),
                onTap: () {},
              ),
            ],
          ),

          ExpansionTile(
            leading: const Icon(Icons.layers),
            title: const Text("Pengaturan Basemap Offline"),
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text("Unduh Berdasarkan AOI"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DownloadAoiPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text("Unduh Berdasarkan Nama Wilayah"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DownloadWilayahPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text("Ungguh Peta"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.layers),
                title: const Text("Daftar Basemap Offline"),
                onTap: () {},
              ),
            ],
          ),

          ListTile(
            leading: const Icon(Icons.folder_copy),
            title: const Text("Daftar Project"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectListPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.directions_walk),
            title: const Text("Rekam Jejak"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
