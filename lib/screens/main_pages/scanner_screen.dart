import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as contacts;
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:barcode_widget/barcode_widget.dart' as bcw;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/camera_data.dart';
import '../../data/scannedcode.dart';
import '../../utils/scan_frame.dart';
import '../scannedBarcodePreview.dart';
import '../scannedQrPreview.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool hasPermission = false;
  bool isFlashOn = false;
  MobileScannerController? scannerController;

  CameraFacingOption currentFacing = CameraFacingOption.back;
  late VoidCallback _cameraFacingListener;

  bool _isProcessing = false;
  bool _dialogShowing = false;
  bool _initDone = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _initScanner());
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
    final status = await Permission.camera.status;
    if (!mounted) return;

    final box = Hive.box('settings');
    final requested = box.get('cameraRequested', defaultValue: false) as bool;

    if (status.isGranted) {
      scannerController = MobileScannerController(
        facing: currentFacing == CameraFacingOption.back
            ? CameraFacing.back
            : CameraFacing.front,
      );
      final autoFlash =
      box.get('autoFlash', defaultValue: false) as bool;
      if (autoFlash) {
        isFlashOn = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) scannerController?.toggleTorch();
        });
      }
      setState(() {
        hasPermission = true;
        _initDone = true;
      });

    } else if (status.isDenied && !requested) {
      _dialogShowing = true;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Camera Permission Needed'),
          content: const Text(
            'This feature requires camera access to scan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                box.put('cameraRequested', true);
                Navigator.pop(context);
                _dialogShowing = false;
                setState(() {
                  hasPermission = false;
                  _initDone = true;
                });
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                box.put('cameraRequested', true);
                Navigator.pop(context);
                _dialogShowing = false;
                Permission.camera.request().then((_) => _initScanner());
              },
              child: const Text('Allow'),
            ),
          ],
        ),
      );

    } else {
      setState(() {
        hasPermission = false;
        _initDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: _initDone
          ? (hasPermission && scannerController != null
          ? _buildScannerView(context)
          : SafeArea(
        child: Center(
          child: ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ),
      ))
          : const Center(child: SizedBox()),
    );
  }

  Widget _buildScannerView(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.5;
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: scannerController!,
          onDetect: _onDetect,
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: ScanFrameOverlay(size: frameSize),
          ),
        ),

        // Bottom bar
        Positioned(
          bottom: size.height * 0.04,
          left: size.width * 0.25,
          right: size.width * 0.25,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                  onPressed: () {
                    final box = Hive.box('settings');
                    final newFacing = currentFacing == CameraFacingOption.back
                        ? CameraFacingOption.front
                        : CameraFacingOption.back;
                    box.put('cameraFacing', newFacing.key);
                  },
                ),
                IconButton(
                  icon: Icon(
                    isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isFlashOn = !isFlashOn;
                      scannerController!.toggleTorch();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    _isProcessing = true;
    final bc = capture.barcodes.first;
    final code = bc.rawValue;
    final isQr = bc.format == BarcodeFormat.qrCode;
    if (code == null) return;

    scannerController?.stop();
    final autoCopy =
    Hive.box('settings').get('autoCopy', defaultValue: false) as bool;
    if (autoCopy) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }

    String fallbackType = 'text';
    if (code.startsWith('BEGIN:VCARD')) {
      fallbackType = 'contact';
    } else if (code.startsWith('http://') ||
        code.startsWith('https://')) {
      fallbackType = 'url';
    }

    final displayFields = <String, String>{};
    if (fallbackType == 'contact') {
      for (final line in code.split('\n')) {
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
      displayFields['URL'] = code;
    } else {
      displayFields['Text'] = code;
    }

    final typeLabel = {
      'contact': 'Contact',
      'url': 'Website',
      'text': 'Text',
    }[fallbackType]!;

    final now = DateTime.now();
    final timestamp =
        '${DateFormat('dd/MM/yy').format(now)} , ${DateFormat('hh:mm a').format(now)}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isQr
            ? ScannedQrPreviewScreen(
          displayTitle: typeLabel,
          rawData: code,
          displayFields: displayFields,
        )
            : ScannedBarcodePreviewScreen(
          displayTitle: typeLabel,
          data: code,
          displayFields: displayFields,
          barcodeSymbology:
          _barcodeFromFormatName(bc.format.name),
        ),
      ),
    ).then((_) async {
      final historyBox = Hive.box<ScannedCode>('scan_history');
      await historyBox.add(ScannedCode(
        title: timestamp,
        isQr: isQr,
        data: code,
        formatName: bc.format.name,
      ));
      scannerController?.start();
      _isProcessing = false;
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
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
