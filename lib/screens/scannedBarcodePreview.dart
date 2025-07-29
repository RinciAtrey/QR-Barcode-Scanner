import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_barcode/utils/constants/colors.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ScannedBarcodePreviewScreen extends StatelessWidget {
  final _screenshotController = ScreenshotController();
  final String displayTitle;
  final Map<String, String> displayFields;
  final Barcode barcodeSymbology;

  ScannedBarcodePreviewScreen({
    Key? key,
    required this.displayTitle,
    required this.displayFields,
    required this.barcodeSymbology,
    required String data,
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
    final raw = displayFields.values.first;
    final size = MediaQuery.of(context).size;
    final hPad = size.width * 0.04;
    final vPad = size.height * 0.03;
    final barWidth = size.width * 0.7;
    final barHeight = size.width * 0.35;

    return Scaffold(
      backgroundColor: AppColors.appColour,
      appBar: AppBar(
        backgroundColor: AppColors.appColour,
        leading: BackButton(color: Colors.white),
        title: Text(
          displayTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // barcode card
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
                    padding: EdgeInsets.all(size.width * 0.06),
                    child: BarcodeWidget(
                      data: raw,
                      barcode: barcodeSymbology,
                      width: barWidth,
                      height: barHeight,
                      drawText: false,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: vPad),

            // details card
            if (displayFields.isNotEmpty)
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: vPad * 0.4,
                    horizontal: hPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, size: size.width * 0.05),
                            tooltip: 'Copy data',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: raw));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),
                      // detail rows
                      ...displayFields.entries.map((e) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: vPad * 0.2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.key}: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: size.width * 0.04,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    letterSpacing: 0.5,
                                    fontSize: size.width * 0.04,
                                  ),
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
    );
  }
}
