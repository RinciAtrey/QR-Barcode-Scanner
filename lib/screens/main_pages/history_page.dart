import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_barcode/screens/scannedQrPreview.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/scannedcode.dart';
import '../scannedBarcodePreview.dart';

Barcode _barcodeFromFormatName(String name) {
  switch (name) {
    case 'code128':    return Barcode.code128();
    case 'code39':     return Barcode.code39();
    case 'code93':     return Barcode.code93();
    case 'ean13':      return Barcode.ean13();
    case 'ean8':       return Barcode.ean8();
    case 'upcE':       return Barcode.upcE();
    case 'dataMatrix': return Barcode.dataMatrix();
    case 'pdf417':     return Barcode.pdf417();
    case 'qrCode':     return Barcode.qrCode();
    default:           return Barcode.code128();
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _box = Hive.box<ScannedCode>('scan_history');
  String _search = '';

  void _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text('This will remove every scanned entry.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _box.clear();
      setState(() {

      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All history deleted')),
      );
    }
  }

  Map<String,String> _fieldsFromQr(ScannedCode c) {
    final m = <String,String>{};
    if (c.title.contains('Contact')) {
      for (final line in c.data.split('\n')) {
        if (line.startsWith('FN:'))    m['Name']  = line.substring(3);
        if (line.startsWith('TEL:'))   m['Phone'] = line.substring(4);
        if (line.startsWith('EMAIL:')) m['Email'] = line.substring(6);
      }
    } else if (c.title.toLowerCase().contains('wifi')) {
      final ssid = RegExp(r'S:([^;]+);').firstMatch(c.data)?.group(1);
      final pass = RegExp(r'P:([^;]+);').firstMatch(c.data)?.group(1);
      if (ssid != null) m['SSID'] = ssid;
      if (pass != null) m['Password'] = pass;
    } else if (c.title.toLowerCase().contains('call')) {
      m['Number'] = c.data.replaceFirst('TEL:', '');
    } else if (c.title.toLowerCase().contains('website')) {
      m['URL'] = c.data;
    } else {
      m['Text'] = c.data;
    }
    return m;
  }

  Map<String,String> _fieldsFromSaved(ScannedCode c) {
    if (!c.isQr) return {'Data': c.data};
    return _fieldsFromQr(c);
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _box.values.toList().reversed.toList();
    final items = _search.isEmpty
        ? allItems
        : allItems.where((c) =>
    c.data.toLowerCase().contains(_search) ||
        c.title.toLowerCase().contains(_search)
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History (${items.length})'),
        actions: [ IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _deleteAll) ],
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
            child: items.isEmpty
                ? const Center(child: Text("No scan history."))
                : ListView.separated(
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
                  onDismissed: (_) => _box.delete(c.key),
                  child: ListTile(
                    leading: Container(
                      width: 50, height: 50, color: Colors.white, alignment: Alignment.center,
                      child: c.isQr
                          ? QrImageView(
                        data: c.data,
                        version: QrVersions.auto,
                        size: 50,
                        backgroundColor: Colors.white,
                      )
                          : BarcodeWidget(
                        data: c.data,
                        barcode: _barcodeFromFormatName(c.formatName),
                        width: 110,
                        height: 80,
                        drawText: false,
                      ),
                    ),
                    title: Text(c.isQr ? 'QR code \n${c.title}' : 'Barcode \n${c.title}'),
                    subtitle: Text(firstValue, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      final typeLabel = c.title.contains('Contact')
                          ? 'Contact'
                          : c.title.toLowerCase().contains('wifi')
                          ? 'Wi‑Fi'
                          : c.data.startsWith(RegExp(r'https?://'))
                          ? 'Website'
                          : 'Text';
                      final displayTitle = '$typeLabel';

                      if (c.isQr) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScannedQrPreviewScreen(
                              displayTitle: displayTitle,
                              rawData: c.data,
                              displayFields: fields,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScannedBarcodePreviewScreen(
                              displayTitle: displayTitle,
                              data: c.data,
                              displayFields: fields,
                              barcodeSymbology: _barcodeFromFormatName(c.formatName),
                            ),
                          ),
                        );
                      }


                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
