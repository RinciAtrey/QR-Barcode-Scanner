// lib/screens/scanned_preview/scanned_qr_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ScannedQrPreviewScreen extends StatelessWidget {
  final String displayTitle;
  final String rawData;
  final Map<String, String> displayFields;

  const ScannedQrPreviewScreen({
    Key? key,
    required this.displayTitle,
    required this.rawData,
    required this.displayFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              data: rawData,
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...displayFields.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Text(
              '${e.key}: ${e.value}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )),
        ],
      ),
    );
  }
}
