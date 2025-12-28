import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import 'map_page.dart';
import 'project/project_detail_page.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  List<Map<String, dynamic>> projects = [];

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future loadProjects() async {
    projects = await DBHelper.instance.getProjects();
    setState(() {});
  }

  void addProject() {
    TextEditingController nameC = TextEditingController();
    TextEditingController ketC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Project"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: "Nama Project"),
            ),
            TextField(
              controller: ketC,
              decoration: const InputDecoration(labelText: "Keterangan"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Simpan"),
            onPressed: () async {
              if (nameC.text.isEmpty) return;

              await DBHelper.instance.insertProject(
                projectId: "PRJ-${DateTime.now().millisecondsSinceEpoch}",
                namaProject: nameC.text,
                keterangan: ketC.text,
                isSync: 0,
                isDelete: 0,
              );

              Navigator.pop(context);
              loadProjects();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showProjectDetail(Map<String, dynamic> project) async {
    final db = await DBHelper.instance.database;

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) as total
    FROM marker_kantor_desa
    WHERE project_id = ? AND is_delete = 0
    ''',
      [project['project_id']],
    );

    final totalMarkerDesa = result.first['total'] as int;
    const totalRekamJejak = 5; // HARD CODE

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Detail Project",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nama Project : ${project['nama_project']}"),
            const SizedBox(height: 8),
            Text("Total Marker Desa : $totalMarkerDesa"),
            Text("Total Rekam Jejak : $totalRekamJejak"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Project")),
      floatingActionButton: FloatingActionButton(
        onPressed: addProject,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: projects.length,
        itemBuilder: (_, i) {
          final p = projects[i];

          return GestureDetector(
            onDoubleTap: () {
              DBHelper.instance.activeProjectId = p['project_id'];

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MapPage()),
              );
            },
            child: ListTile(
              leading: const Icon(Icons.folder),
              title: Text(p["nama_project"] ?? ""),
              subtitle: Text(p["keterangan"] ?? ""),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case "edit":
                      break;
                    case "detail":
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(project: p),
                        ),
                      );
                      break;
                    case "sync":
                      break;
                    case "export":
                      break;
                    case "delete":
                      break;
                  }
                },

                itemBuilder: (_) => const [
                  PopupMenuItem(value: "edit", child: Text("Edit Nama")),
                  PopupMenuItem(value: "detail", child: Text("Detail")),
                  PopupMenuItem(value: "sync", child: Text("Sinkronisasi")),
                  PopupMenuItem(value: "export", child: Text("Export")),
                  PopupMenuItem(value: "delete", child: Text("Hapus")),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
