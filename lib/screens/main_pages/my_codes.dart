import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:qr_barcode/qr/preview_qr_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../barcode/generate_barcode.dart';
import '../../barcode/preview_barcode_screen.dart';
import '../../data/generate_code.dart';
import '../../data/savedcode.dart';


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
    case 'QR Code':
      return Barcode.qrCode();
    case 'Data Matrix':
      return Barcode.dataMatrix();
    case 'PDF417':
      return Barcode.pdf417();
    default:
      throw ArgumentError('Unknown barcode type "$name"');
  }
}

class MyCodes extends StatefulWidget {
  const MyCodes({super.key});

  @override
  State<MyCodes> createState() => _MyCodesState();
}

class _MyCodesState extends State<MyCodes> {
  final _box = Hive.box<SavedCode>('saved_codes');
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Codes'),
          leading: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const GenerateCode(),
              );
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Search",
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (ctx, Box<SavedCode> box, _) {
                  // get and sort
                  var codes = box.values.toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  // filter by search
                  if (_search.isNotEmpty) {
                    codes = codes
                        .where((c) => c.title.toLowerCase().contains(_search))
                        .toList();
                  }
                  if (codes.isEmpty) {
                    return Center(child: Text("No saved codes yet."));
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(12),
                    itemCount: codes.length,
                    separatorBuilder: (_, __) => Divider(thickness: 1),
                    itemBuilder: (context, index) {
                      final c = codes[index];
                      return Dismissible(
                        key: ValueKey(c.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          box.delete(c.key);
                        },
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: c.isQr
                                ? QrImageView(
                              data: " ",
                              version: QrVersions.auto,
                              size: 50,
                              backgroundColor: Colors.white,
                            )
                                : BarcodeWidget(
                              data: '',
                              barcode: _barcodeFromName(c.title),
                              width: 110,
                              height: 80,
                              drawText: false,
                              color: Colors.black,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          title: Text(
                            c.isQr
                                ? 'QR code · ${c.title}'
                                : 'Barcode · ${c.title}',
                          ),
                          subtitle: Text(
                            c.data,                  // ← show the actual encoded string
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            if (c.isQr) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QRPreviewScreen(
                                    title: 'QR code · ${c.title}',
                                    data: '',
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PreviewBarcodeScreen(
                                    type: BarcodeOption(
                                        c.title, _barcodeFromName(c.title)),
                                    data: '',
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
      ),
    );
  }
}





