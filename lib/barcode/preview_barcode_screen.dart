import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../data/savedcode.dart';
import 'generate_barcode.dart';
import 'package:hive/hive.dart';


class PreviewBarcodeScreen extends StatelessWidget {
  final BarcodeOption type;
  final String data;
  final Map<String, String> displayFields;

  const PreviewBarcodeScreen({
    Key? key,
    required this.type,
    required this.data,
    this.displayFields = const {},
  }) : super(key: key);


  Future<void> _share(BuildContext ctx) async {
    final controller = ScreenshotController();
    final bytes = await controller.captureFromWidget(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: BarcodeWidget(
          data: data,
          barcode: type.barcode,
          width: 300,
          height: 170,
        ),
      ),
      delay: const Duration(milliseconds: 100),
    );
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/bar_code.png';
    final capture = await controller.capture();
    if (capture == null) return null;

    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(capture);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath)],
        text: 'Share a OR Code',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: BackButton(color: Colors.white),
        title: Text(type.name, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: () async {
              final box = Hive.box<SavedCode>('saved_codes');
              await box.add(SavedCode(
                  title: type.name,
                  isQr: false,
                  data: data
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barcode saved')),
              );
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),

        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: BarcodeWidget(
                data: data,
                barcode: type.barcode,
                width: 250,
                height: 80,
                drawText: true,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            for (final entry in displayFields.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    SelectableText(entry.value,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
