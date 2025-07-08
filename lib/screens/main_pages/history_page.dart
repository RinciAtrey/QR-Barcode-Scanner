import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/savedcode.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<SavedCode>('scan_history');

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History (${box.length})'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<SavedCode> b, _) {
          final items = b.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (items.isEmpty) {
            return Center(child: Text('No scans yet.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, i) {
              final c = items[i];
              return ListTile(
                leading: SizedBox(
                  width: 60,
                  height: 60,
                  child: QrImageView(
                    data: '',
                    version: QrVersions.auto,
                    size: 60,
                  ),
                ),
                title: Text(c.title),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () {
                    b.delete(c.key);
                  },
                ),
                onTap: () {
                },
              );
            },
          );
        },
      ),
    );
  }
}
