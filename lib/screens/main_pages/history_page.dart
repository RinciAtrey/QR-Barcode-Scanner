import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_barcode/screens/scannedQrPreview.dart';
import 'package:qr_barcode/utils/constants/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/scannedcode.dart';
import '../../main.dart';
import '../scannedBarcodePreview.dart';

Barcode _barcodeFromFormatName(String name) {
  switch (name) {
    case 'code128':
      return Barcode.code128();
    case 'code39':
      return Barcode.code39();
    case 'code93':
      return Barcode.code93();
    case 'ean13':
      return Barcode.ean13();
    case 'ean8':
      return Barcode.ean8();
    case 'upcE':
      return Barcode.upcE();
    case 'dataMatrix':
      return Barcode.dataMatrix();
    case 'pdf417':
      return Barcode.pdf417();
    case 'qrCode':
      return Barcode.qrCode();
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
  final _box = Hive.box<ScannedCode>('scan_history');
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

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
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All history deleted')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Map<String, String> _fieldsFromQr(ScannedCode c) {
    final m = <String, String>{};
    if (c.title.contains('Contact')) {
      for (final line in c.data.split('\n')) {
        if (line.startsWith('FN:')) m['Name'] = line.substring(3);
        if (line.startsWith('TEL:')) m['Phone'] = line.substring(4);
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

  Map<String, String> _fieldsFromSaved(ScannedCode c) {
    if (!c.isQr) return {'Data': c.data};
    return _fieldsFromQr(c);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final allItems = _box.values.toList().reversed.toList();
    final items = _search.isEmpty
        ? allItems
        : allItems.where((c) {
      final searchLower = _search;

      final displayTitle = (c.isQr ? 'QR code · ' : 'Barcode · ') + c.title;
      final titleLower   = displayTitle.toLowerCase();

      final dataLower    = c.data.toLowerCase();

      final firstValueLower = c.isQr
          ? (_fieldsFromSaved(c).values.first.toLowerCase())
          : '';

      return titleLower.contains(searchLower)
          || dataLower.contains(searchLower)
          || firstValueLower.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Scan History',
          style: TextStyle(color: AppColors.appColour, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.appColour),
            onPressed: _deleteAll,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04,
              vertical: mq.height * 0.01,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search",
                      border: InputBorder.none,
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: mq.width * 0.04,
                        vertical: mq.height * 0.015,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppColors.appColour),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, size: 20,),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),

                    ),
                    onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04,
              vertical: mq.height * 0.005,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: mq.width * 0.06,
                      color: AppColors.appColour,
                    ),
                  ),
                ),
                const Divider(thickness: 1),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "No scanned codes yet.",
                    style: TextStyle(fontSize: mq.width * 0.045),
                  ),
                  SizedBox(height: mq.height * 0.02),
                  ElevatedButton.icon(
                    onPressed: () {
                      final homeState = HomeScreen.globalKey.currentState;
                      homeState?.switchTo(0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.appColour,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: mq.width * 0.06,
                        vertical: mq.height * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.qr_code_scanner, size: mq.width * 0.06),
                    label: Text(
                      "Scan Code",
                      style: TextStyle(fontSize: mq.width * 0.045),
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: mq.width * 0.04,
                vertical: mq.height * 0.01,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(thickness: 1),
              itemBuilder: (context, index) {
                final c = items[index];
                final fields = _fieldsFromSaved(c);
                final firstValue =
                fields.values.isNotEmpty ? fields.values.first : '';

                return Dismissible(
                  key: ValueKey(c.key),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _box.delete(c.key),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: mq.width * 0.03,
                      vertical: mq.height * 0.01,
                    ),
                    leading: Container(
                      width: mq.width * 0.15,
                      height: mq.width * 0.15,
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: c.isQr
                          ? QrImageView(
                        data: c.data,
                        version: QrVersions.auto,
                        size: mq.width * 0.15,
                        backgroundColor: Colors.white,
                      )
                          : BarcodeWidget(
                        data: c.data,
                        barcode: _barcodeFromFormatName(c.formatName),
                        width: mq.width * 0.3,
                        height: mq.height * 0.1,
                        drawText: false,
                      ),
                    ),
                    title: Text(
                      c.isQr ? 'QR code · ${c.title}' : 'Barcode · ${c.title}',
                      style: TextStyle(fontSize: mq.width * 0.045),
                    ),
                    subtitle: Text(
                      firstValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: mq.width * 0.035),
                    ),
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
                              barcodeSymbology:
                              _barcodeFromFormatName(c.formatName),
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
