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
import 'package:wifi_iot/wifi_iot.dart';
import '../../data/camera_data.dart';
import '../../data/scannedcode.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/snackbar.dart';
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
      final autoFlash = box.get('autoFlash', defaultValue: false) as bool;
      if (autoFlash) {
        isFlashOn = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          if (!mounted) return;
          await scannerController?.toggleTorch();
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
  String _extractWiFiValue(String payload, String key) {
    final regex = RegExp(r'$key:([^;]+);'.replaceFirst('\$key', key));
    final match = regex.firstMatch(payload);
    return match?.group(1) ?? '';
  }


  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: _initDone
          ? (hasPermission && scannerController != null
          ? _buildScannerView(context, mq)
          : SafeArea(
        child: Center(
          child: ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: mq.width * 0.08,
                vertical: mq.height * 0.018,
              ),
            ),
            child: Text(
              'Open Settings',
              style: TextStyle(fontSize: mq.width * 0.045),
            ),
          ),
        ),
      ))
          : const Center(child: SizedBox()),
    );
  }

  Widget _buildScannerView(BuildContext context, Size mq) {
    final frameSize = mq.width * 0.5;
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
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: mq.height * 0.04),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: mq.height * 0.015,
                horizontal: mq.width * 0.05,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(mq.width * 0.03),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,        //only as wide as its children
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.flip_camera_ios_rounded,
                      color: Colors.white,
                      size: mq.width * 0.07,
                    ),
                    onPressed: () {
                      final box = Hive.box('settings');
                      final newFacing = currentFacing == CameraFacingOption.back
                          ? CameraFacingOption.front
                          : CameraFacingOption.back;
                      box.put('cameraFacing', newFacing.key);
                    },
                  ),
                  SizedBox(width: mq.width * 0.07),     //gap between icons
                  IconButton(
                    icon: Icon(
                      isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: mq.width * 0.07,
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
        ),
      ],
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
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
        AppSnackBar.success('Copied to the clipboard'),
      );
    }
    if (code.startsWith(RegExp(r'https?://'))) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: const [
              Icon(Icons.link, color: AppColors.appColour),
              SizedBox(width: 8),
              Text(
                'Open Link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            "URL: $code",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _launchURL(code);
                scannerController?.start();
                _isProcessing = false;
              },
              child: const Text('Launch'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.appColour,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context);
                scannerController?.start();
                _isProcessing = false;
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }


    if (code.startsWith('WIFI:')) {
      final ssid = _extractWiFiValue(code, 'S');
      final pwd  = _extractWiFiValue(code, 'P');
      final auth = _extractWiFiValue(code, 'T');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: const [
              Icon(Icons.wifi, color: AppColors.appColour),
              SizedBox(width: 8),
              Text(
                'Connect to Wi‑Fi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'SSID: $ssid\nPassword: $pwd\nSecurity: $auth',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                NetworkSecurity securityEnum;
                switch (auth.toUpperCase()) {
                  case 'WEP':
                    securityEnum = NetworkSecurity.WEP;
                    break;
                  case 'WPA':
                    securityEnum = NetworkSecurity.WPA;
                    break;
                  default:
                    securityEnum = NetworkSecurity.NONE;
                }
                WiFiForIoTPlugin.connect(
                  ssid,
                  password: pwd,
                  security: securityEnum,
                ).then((connected) {
                  if (connected == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppSnackBar.success('Connected to $ssid'),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppSnackBar.success('Failed to connect to $ssid'),
                    );
                  }
                  // restart scanning:
                  scannerController?.start();
                  _isProcessing = false;
                });
              },
              child: const Text('Connect'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.appColour,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context);
                scannerController?.start();
                _isProcessing = false;
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success('Contact saved'),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.success('Failed!'),
      );
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
