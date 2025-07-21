import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as contacts;
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:barcode_widget/barcode_widget.dart' as bcw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/camera_data.dart';
import '../../data/scannedcode.dart';
import '../scannedBarcodePreview.dart';
import '../scannedQrPreview.dart';
import 'history_page.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool hasPermission = false;
  bool isFlashOn = false;
  MobileScannerController? scannerController;
  late CameraFacingOption currentFacing;
  late VoidCallback _cameraFacingListener;



  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    currentFacing = CameraFacingOptionX.fromKey(
      box.get('cameraFacing', defaultValue: CameraFacingOption.back.key) as String,
    );
    _cameraFacingListener = () {
      final newKey = box.get('cameraFacing') as String;
      final newFacing = CameraFacingOptionX.fromKey(newKey);
      if (newFacing != currentFacing && scannerController != null) {
        scannerController!.switchCamera();
        currentFacing = newFacing;
      }
    };
    box.listenable(keys: ['cameraFacing']).addListener(_cameraFacingListener);
    _initScanner();
  }

  @override
  void dispose() {
    Hive.box('settings')
        .listenable(keys: ['cameraFacing'])
        .removeListener(_cameraFacingListener);
    scannerController?.dispose();
    super.dispose();
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      scannerController = MobileScannerController(
        facing: currentFacing == CameraFacingOption.back
            ? CameraFacing.back
            : CameraFacing.front,
      );
      final autoFlash =
      Hive.box('settings').get('autoFlash', defaultValue: false) as bool;
      if (autoFlash) isFlashOn = true;
      setState(() => hasPermission = true);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await scannerController?.start();
        if (autoFlash) await scannerController?.toggleTorch();
      });
    } else if (status.isPermanentlyDenied) {
      setState(() => hasPermission = false);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Camera Permission'),
          content: const Text(
            'Camera access has been permanently denied.\n'
                'Please enable it in your device Settings.',
          ),
          actions: [
            TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Open Settings')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
          ],
        ),
      );
    } else {
      setState(() => hasPermission = false);
    }
  }

  Future<void> _processScannedData(
      String data,
      bool isQr,
      String displayTitle,
      String formatName,
      ) async {
    await scannerController?.stop();

    final autoCopy =
    Hive.box('settings').get('autoCopy', defaultValue: false) as bool;
    if (autoCopy) {
      await Clipboard.setData(ClipboardData(text: data));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }

    String fallbackType = 'text';
    if (data.startsWith('BEGIN:VCARD')) {
      fallbackType = 'contact';
    } else if (data.startsWith('http://') || data.startsWith('https://')) {
      fallbackType = 'url';
    }

    final displayFields = <String, String>{};
    if (fallbackType == 'contact') {
      for (final line in data.split('\n')) {
        if (line.startsWith('FN:')) {
          displayFields['Name'] = line.substring(3);
        }
        if (line.startsWith('TEL:')) {
          displayFields['Phone'] = line.substring(4);
        }
        if (line.startsWith('EMAIL:')) {
          displayFields['Email'] = line.substring(6);
        }
      }
    } else if (fallbackType == 'url') {
      displayFields['URL'] = data;
    } else {
      displayFields['Text'] = data;
    }

    if (isQr) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScannedQrPreviewScreen(
            displayTitle: displayTitle,
            rawData: data,                    // <-- the full vCard/URL/etc.
            displayFields: displayFields,
          ),
        ),
      );
    } else {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScannedBarcodePreviewScreen(
            displayTitle: displayTitle,
            data: data,
            displayFields: displayFields,
            barcodeSymbology: _barcodeFromFormatName(formatName),
          ),
        ),
      );
    }

    // then save to Hive
    final historyBox = Hive.box<ScannedCode>('scan_history');
    await historyBox.add(ScannedCode(
      title: displayTitle,
      isQr: isQr,
      data: data,
      formatName: formatName,
    ));

    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HistoryPage()));
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  Future<void> _saveContact(String vcard) async {
    final lines = vcard.split('\n');
    String? name, phone, email;
    for (var l in lines) {
      if (l.startsWith('FN:')) name = l.substring(3);
      if (l.startsWith('TEL:')) phone = l.substring(4);
      if (l.startsWith('EMAIL:')) email = l.substring(5);
    }
    final contact = contacts.Contact()
      ..name.first = name ?? ''
      ..phones = [contacts.Phone(phone ?? '')]
      ..emails = [contacts.Email(email ?? '')];
    try {
      await contact.insert();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Contact Saved")));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission || scannerController == null) {
      return Scaffold(
        backgroundColor: Colors.indigo,
        appBar: AppBar(title: const Text("Scanner"), backgroundColor: Colors.indigo),
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Camera Permission is required"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initScanner,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text("Grant Permission"),
          ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: Colors.indigo,
      appBar: AppBar(
        title: const Text("Scan QR / Barcode"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                isFlashOn = !isFlashOn;
                scannerController!.toggleTorch();
              });
            },
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: scannerController!,
          onDetect: (capture) {
            final bc = capture.barcodes.first;
            final code = bc.rawValue;
            final isQr = bc.format == BarcodeFormat.qrCode;
            if (code != null) {
              final now = DateTime.now();
              final date = DateFormat('dd/MM/yy').format(now);
              final time = DateFormat('hh:mm a').format(now);
              final title = '$date , $time';
              _processScannedData(code, isQr, title, bc.format.name);
            }
          },
        ),
        const Positioned(
          bottom: 24, left: 0, right: 0,
          child: Center(
            child: Text(
              'Align code within the frame',
              style: TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

bcw.Barcode _barcodeFromFormatName(String name) {
  switch (name) {
    case 'code128':
      return bcw.Barcode.code128();
    case 'code39':
      return bcw.Barcode.code39();
    case 'code93':
      return bcw.Barcode.code93();
    case 'ean13':
      return bcw.Barcode.ean13();
    case 'ean8':
      return bcw.Barcode.ean8();
    case 'upcE':
      return bcw.Barcode.upcE();
    case 'dataMatrix':
      return bcw.Barcode.dataMatrix();
    case 'pdf417':
      return bcw.Barcode.pdf417();
    case 'qrCode':
      return bcw.Barcode.qrCode();
    default:
      return bcw.Barcode.code128();
  }
}
