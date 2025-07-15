import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../data/savedcode.dart';

class QRPreviewScreen extends StatelessWidget {
  final String title;
  final String data;
  final Map<String, String> displayFields;
  const QRPreviewScreen({super.key, required this.title, required this.data, this.displayFields=const {}});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: BackButton(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              Share.share(data);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: () async {
              final box = Hive.box<SavedCode>('saved_codes');
              await box.add(SavedCode(
                title: title,
                isQr: true,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR code saved')),
              );
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(data: data, version: QrVersions.auto, size: 250),
            ),
            const SizedBox(height: 12,),
            ...displayFields.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${e.key}: ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SelectableText(
                    e.value,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )),
          ],
        ),

      ),
    );
  }
  }

