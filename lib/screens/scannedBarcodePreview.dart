import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class ScannedBarcodePreviewScreen extends StatelessWidget {
  final String displayTitle;
  final Map<String, String> displayFields;
  final Barcode barcodeSymbology;

  const ScannedBarcodePreviewScreen({
    Key? key,
    required this.displayTitle,
    required this.displayFields,
    required this.barcodeSymbology, required String data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final raw = displayFields.values.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: BarcodeWidget(
              data: raw,
              barcode: barcodeSymbology,
              width: 300,
              height: 120,
              drawText: false,
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
