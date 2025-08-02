import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive/hive.dart';

import '../ads/ad_helper.dart';
import '../ads/ad_units.dart';
import '../data/savedcode.dart';
import '../utils/constants/snackbar.dart';
import 'generate_barcode.dart';
import 'package:qr_barcode/utils/constants/colors.dart';

class PreviewBarcodeScreen extends StatelessWidget {
  final _screenshotController = ScreenshotController();
  final BarcodeOption type;
  final String data;
  final Map<String, String> displayFields;

   PreviewBarcodeScreen({
    Key? key,
    required this.type,
    required this.data,
    this.displayFields = const {},
  }) : super(key: key);

  Future<void> _share(BuildContext ctx) async {
    final bytes = await _screenshotController.capture();
    if (bytes == null) return;

    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/bar_code.png';
    await File(path).writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(path)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appColour,
      appBar: AppBar(
        backgroundColor: AppColors.appColour,
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
                data: data,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                AppSnackBar.success('Barcode saved.'),
              );
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Card(
                color: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: BarcodeWidget(
                        data: data,
                        barcode: type.barcode,
                        width: 300,
                        height: 170,
                        drawText: true,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (displayFields.isNotEmpty)
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Details',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy data',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: data));
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackBar.success('Copied to the clipboard'),
                              );
                            },
                          ),

                        ],
                      ),
                      const Divider(thickness: 1),
                      // Detail rows
                      ...displayFields.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.key}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              Expanded(
                                child: SelectableText(
                                  e.value,
                                  style: const TextStyle(letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AdaptiveBannerAd(adUnitId: AdUnits.banner2),
          ],
        ),
      ),
    );
  }
}
