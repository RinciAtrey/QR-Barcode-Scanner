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
import '../../main.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/snackbar.dart';

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
  final TextEditingController _searchController = TextEditingController();

  void _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        title: Row(
          children: const [
            Icon(Icons.warning_amber,color: AppColors.appColour, ),
            SizedBox(width: 8),
            Text(
              'Delete all codes?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will remove every saved code.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: AppColors.appColour,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _box.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success('All codes deleted'),
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Codes',
            style: TextStyle(color: AppColors.appColour, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.add, color: AppColors.appColour),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const GenerateCode(),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppColors.appColour),
              tooltip: 'Delete all',
              onPressed: _deleteAll,
            ),
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: mq.width * 0.04,
                          vertical: mq.height * 0.015,
                        ),
                        fillColor: Colors.grey.shade200,
                        filled: true,
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
            ValueListenableBuilder<Box<SavedCode>>(
              valueListenable: _box.listenable(),
              builder: (_, box, __) {
                var codes = box.values.toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                if (_search.isNotEmpty) {
                  final s = _search;
                  codes = codes.where((c) {
                    final title = ((c.isQr ? 'QR code · ' : 'Barcode · ') + c.title).toLowerCase();
                    final data  = c.data.toLowerCase();
                    final extra = c.isQr
                        ? _fieldsFromSaved(c).values.first.toLowerCase()
                        : '';
                    return title.contains(s) || data.contains(s) || extra.contains(s);
                  }).toList();
                }
                return Padding(
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
                          '${codes.length}',
                          style: TextStyle(
                            fontSize: mq.width * 0.06,
                            color: AppColors.appColour,
                          ),
                        ),
                      ),
                      const Divider(thickness: 1),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (ctx, Box<SavedCode> box, _) {
                  // get and sort
                  var codes = box.values.toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (_search.isNotEmpty) {
                    final searchLower = _search;
                    codes = codes.where((c) {
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
                  }

                  if (codes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "No saved codes yet.",
                            style: TextStyle(fontSize: mq.width * 0.045,
                              color: Theme.of(context).colorScheme.onSurface,),
                          ),
                          SizedBox(height: mq.height * 0.02),
                          ElevatedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const GenerateCode(),
                              );
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
                            icon: Icon(Icons.add_circle_outline, size: mq.width * 0.06),
                            label: Text(
                              "Create code",
                              style: TextStyle(fontSize: mq.width * 0.045),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return
                    Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: mq.width * 0.02,
                        vertical: mq.height * 0.01,
                      ),
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
                            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            box.delete(c.key);
                          },
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
                                barcode: _barcodeFromName(c.title),
                                width: mq.width * 0.3,
                                height: mq.height * 0.1,
                                drawText: false,
                                color: Colors.black,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            title: Text(
                              c.isQr ? 'QR code · ${c.title}' : 'Barcode · ${c.title}',
                              style: TextStyle(fontSize: mq.width * 0.045),
                            ),
                            subtitle: Builder(builder: (_) {
                              final fields = _fieldsFromSaved(c);
                              final firstValue = fields.values.isNotEmpty ? fields.values.first : '';
                              return Text(
                                firstValue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: mq.width * 0.035),
                              );
                            }),
                            onTap: () {
                              final fields = c.isQr
                                  ? _fieldsFromQr(c)
                                  : <String, String>{'Data': c.data};
                              if (c.isQr) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QRPreviewScreen(
                                      title: '${c.title}',
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
                                      type: BarcodeOption(
                                          c.title, _barcodeFromName(c.title)),
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
                    ),
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

Map<String, String> _fieldsFromQr(SavedCode c) {
  final m = <String, String>{};

  // 1) Contact
  if (c.title.contains('Contact')) {
    for (final line in c.data.split('\n')) {
      if (line.startsWith('FN:')) m['Name'] = line.substring(3);
      if (line.startsWith('TEL:')) m['Phone'] = line.substring(4);
      if (line.startsWith('EMAIL:')) m['Email'] = line.substring(6);
    }

    // 2) Wi-Fi
  } else if (c.title.toLowerCase().contains('wifi')) {
    final ssidMatch = RegExp(r'S:([^;]+);').firstMatch(c.data);
    final passMatch = RegExp(r'P:([^;]+);').firstMatch(c.data);
    if (ssidMatch != null) m['SSID'] = ssidMatch.group(1)!;
    if (passMatch != null) m['Password'] = passMatch.group(1)!;

    // 3) Telephone
  } else if (c.title.toLowerCase().contains('call')) {
    m['Number'] = c.data.replaceFirst('TEL:', '');

    // 4) Website
  } else if (c.title.toLowerCase().contains('website')) {
    m['URL'] = c.data;

    // 5) Plain Text
  } else {
    m['Text'] = c.data;
  }

  return m;
}

Map<String, String> _fieldsFromSaved(SavedCode c) {
  if (!c.isQr) {
    return {'Data': c.data};
  }

  // QR codes:
  final m = <String, String>{};
  if (c.title.contains('Contact')) {
    for (final line in c.data.split('\n')) {
      if (line.startsWith('FN:')) m['Name'] = line.substring(3);
      if (line.startsWith('TEL:')) m['Phone'] = line.substring(4);
      if (line.startsWith('EMAIL:')) m['Email'] = line.substring(6);
    }
  } else if (c.title.contains('Wifi')) {
    final ssidMatch = RegExp(r'S:([^;]+);').firstMatch(c.data);
    final passMatch = RegExp(r'P:([^;]+);').firstMatch(c.data);
    if (ssidMatch != null) m['SSID'] = ssidMatch.group(1)!;
    if (passMatch != null) m['Password'] = passMatch.group(1)!;
  } else if (c.title.contains('Call')) {
    m['Number'] = c.data.replaceFirst('TEL:', '');
  } else {
    // show everything
    m['Data'] = c.data;
  }
  return m;
}
