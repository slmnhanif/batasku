import 'package:flutter/material.dart';
import '/pages/downloadWilayah_page.dart';
import '/pages/downloadaOI_page.dart';
import '/pages/projectList_page.dart';

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
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            accountName: Text(
              "Hai, $username",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text(""),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
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
