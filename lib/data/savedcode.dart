import 'package:hive/hive.dart';

part 'savedcode.g.dart';

@HiveType(typeId: 0)
class SavedCode extends HiveObject {
  @HiveField(0)
  String title;        // “EAN‑8” or “QR code · Text”

  @HiveField(1)
  bool isQr;           // true = QR, false = barcode

  @HiveField(2)
  String data;

  @HiveField(3)
  DateTime createdAt;  // timestamp

  SavedCode({
    required this.title,
    required this.isQr,
    required this.data,
  }) : createdAt = DateTime.now();
}
