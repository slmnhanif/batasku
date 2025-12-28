import 'package:flutter/material.dart';
import '../../db/db_helper.dart';

class ProjectDetailPage extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  int totalKantorDesa = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final db = await DBHelper.instance.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM marker_kantor_desa
      WHERE project_id = ? AND is_delete = 0
      ''',
      [widget.project['project_id']],
    );

    setState(() {
      totalKantorDesa = result.first['total'] as int;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project['nama_project'])),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item(
            icon: Icons.account_balance,
            title: 'Lokasi Kantor Desa',
            total: totalKantorDesa,
          ),
          _item(icon: Icons.location_on, title: 'Titik Batas', total: 0),
          _item(icon: Icons.show_chart, title: 'Garis Batas Desa', total: 0),
          _item(icon: Icons.directions_walk, title: 'Rekam Jejak', total: 0),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required int total,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 26),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          Text('$total Object', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
