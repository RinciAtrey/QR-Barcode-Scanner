import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_barcode/utils/constants/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/constants/snackbar.dart';

class ScannedQrPreviewScreen extends StatelessWidget {
  final _screenshotController = ScreenshotController();
  final String displayTitle;
  final String rawData;
  final Map<String, String> displayFields;

  ScannedQrPreviewScreen({
    Key? key,
    required this.displayTitle,
    required this.rawData,
    required this.displayFields,
  }) : super(key: key);


  Future<void> _share(BuildContext ctx) async {
    final bytes = await _screenshotController.capture();
    if (bytes == null) return;

    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/qr_code.png';
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Center(
                    child: QrImageView(
                      data: rawData,
                      version: QrVersions.auto,
                      size: 260,
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header with copy button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Details',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy data',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: rawData));
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackBar.success('Copied to the clipboard'),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),
                      ...displayFields.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.key}: ',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: SelectableText(
                                e.value,
                                style: const TextStyle(letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      )),
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
