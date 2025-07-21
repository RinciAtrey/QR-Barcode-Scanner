import 'package:hive/hive.dart';

part 'scannedcode.g.dart';

@HiveType(typeId: 2)
class ScannedCode extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isQr;

  @HiveField(2)
  String data;

  @HiveField(3)
  String formatName;

  ScannedCode({
    required this.title,
    required this.isQr,
    required this.data,
    required this.formatName,
  });
}
