import 'package:flutter/material.dart';
import '../db/db_helper.dart';

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
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(p["nama_project"] ?? ""),
            subtitle: Text(p["keterangan"] ?? ""),

            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case "edit":
                    // editProject(p);
                    break;
                  case "detail":
                    // showDetail(p);
                    break;
                  case "sync":
                    // syncProject(p);
                    break;
                  case "export":
                    // exportProject(p);
                    break;
                  case "delete":
                    // deleteProject(p);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: "edit", child: Text("Edit Nama")),
                const PopupMenuItem(value: "detail", child: Text("Detail")),
                const PopupMenuItem(value: "sync", child: Text("Sinkronisasi")),
                const PopupMenuItem(value: "export", child: Text("Export")),
                const PopupMenuItem(value: "delete", child: Text("Hapus")),
              ],
            ),
          );
        },
      ),
    );
  }
}
