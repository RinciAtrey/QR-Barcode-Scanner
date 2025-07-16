import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/savedcode.dart';
import '../../barcode/generate_barcode.dart';
import '../../barcode/preview_barcode_screen.dart';
import 'package:qr_barcode/qr/preview_qr_screen.dart';

// helper to map a saved title back to its Barcode instance
Barcode _barcodeFromName(String name) {
  switch (name) {
    case 'Code 128':
      return Barcode.code128();
    case 'Code 39':
      return Barcode.code39();
    case 'Code 93':
      return Barcode.code93();
    case 'EAN-13':
      return Barcode.ean13();
    case 'EAN-8':
      return Barcode.ean8();
    case 'UPC-E':
      return Barcode.upcE();
    case 'Data Matrix':
      return Barcode.dataMatrix();
    case 'PDF417':
      return Barcode.pdf417();
    default:
      return Barcode.code128();
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _box = Hive.box<SavedCode>('scan_history');
  String _search = '';

  void _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text('This will remove every scanned entry.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _box.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All history deleted')));
    }
  }

  Map<String,String> _fieldsFromQr(SavedCode c) {
    final m = <String,String>{};
    if (c.title.contains('Contact')) {
      for (final line in c.data.split('\n')) {
        if (line.startsWith('FN:'))    m['Name']  = line.substring(3);
        if (line.startsWith('TEL:'))   m['Phone'] = line.substring(4);
        if (line.startsWith('EMAIL:')) m['Email'] = line.substring(6);
      }
    } else if (c.title.toLowerCase().contains('wifi')) {
      final ssidMatch = RegExp(r'S:([^;]+);').firstMatch(c.data);
      final passMatch = RegExp(r'P:([^;]+);').firstMatch(c.data);
      if (ssidMatch != null) m['SSID']     = ssidMatch.group(1)!;
      if (passMatch != null) m['Password'] = passMatch.group(1)!;
    } else if (c.title.toLowerCase().contains('call')) {
      m['Number'] = c.data.replaceFirst('TEL:', '');
    } else if (c.title.toLowerCase().contains('website')) {
      m['URL'] = c.data;
    } else {
      m['Text'] = c.data;
    }
    return m;
  }

  Map<String,String> _fieldsFromSaved(SavedCode c) {
    if (!c.isQr) {
      return {'Data': c.data};
    }
    return _fieldsFromQr(c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History (${_box.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _deleteAll),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(labelText: "Search", suffixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (ctx, Box<SavedCode> box, _) {
                var items = box.values.toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                if (_search.isNotEmpty) {
                  items = items.where((c) =>
                  c.data.toLowerCase().contains(_search) ||
                      c.title.toLowerCase().contains(_search)
                  ).toList();
                }
                if (items.isEmpty) {
                  return const Center(child: Text("No scan history."));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(thickness: 1),
                  itemBuilder: (context, index) {
                    final c = items[index];
                    final fields = _fieldsFromSaved(c);
                    final firstValue = fields.values.isNotEmpty ? fields.values.first : '';
                    return Dismissible(
                      key: ValueKey(c.key),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => box.delete(c.key),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: c.isQr
                              ? QrImageView(data: c.data, version: QrVersions.auto, size: 50, backgroundColor: Colors.white)
                              : BarcodeWidget(
                            data: c.data,
                            barcode: _barcodeFromName(c.title),
                            width: 110,
                            height: 80,
                            drawText: false,
                            color: Colors.black,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        title: Text(c.isQr ? 'QR · ${c.title}' : 'BC · ${c.title}'),
                        subtitle: Text(firstValue, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => box.delete(c.key)),
                        onTap: () {
                          if (c.isQr) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QRPreviewScreen(
                                  title: c.title,
                                  data: c.data,
                                  displayFields: fields,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PreviewBarcodeScreen(
                                  type: BarcodeOption(c.title, _barcodeFromName(c.title)),
                                  data: c.data,
                                  displayFields: fields,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
