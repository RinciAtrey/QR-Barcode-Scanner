import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_barcode/utils/constants/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../data/savedcode.dart';

class QRPreviewScreen extends StatelessWidget {
  final _screenshotController = ScreenshotController();
  final String title;
  final String data;
  final Map<String, String> displayFields;
  QRPreviewScreen({
    super.key,
    required this.title,
    required this.data,
    this.displayFields = const {},
  });

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
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.04;
    final verticalPadding = size.height * 0.03;
    final qrSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: AppColors.appColour,
      appBar: AppBar(
        backgroundColor: AppColors.appColour,
        leading: BackButton(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
                title: title,
                isQr: true,
                data: data,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR code saved')),
              );
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
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
                      padding: EdgeInsets.all(size.width * 0.06),
                      child: QrImageView(
                        data: data,
                        version: QrVersions.auto,
                        size: qrSize,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: verticalPadding),

              if (displayFields.isNotEmpty)
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding * 0.4,
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              icon: Icon(
                                Icons.copy,
                                size: size.width * 0.05,
                              ),
                              tooltip: 'Copy details',
                              onPressed: () {
                                final detailsString = displayFields.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join('\n');
                                Clipboard.setData(ClipboardData(text: detailsString));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                        const Divider(thickness: 1),
                        ...displayFields.entries.map((e) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: verticalPadding * 0.2,
                            ),
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
                                  child: SelectableText(
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
      ),
    );
  }
}
