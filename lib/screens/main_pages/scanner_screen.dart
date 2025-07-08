import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as contacts;
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_barcode/data/savedcode.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/camera_data.dart';
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
      setState(() => hasPermission = true);

      scannerController = MobileScannerController(
        facing: currentFacing == CameraFacingOption.back
            ? CameraFacing.back
            : CameraFacing.front,
      );

      // explicitly start the camera preview
      await scannerController!.start();

      // now it’s safe to toggle the torch
      final autoFlash = Hive.box('settings')
          .get('autoFlash', defaultValue: false) as bool;
      if (autoFlash) {
        await scannerController!.toggleTorch();
        setState(() => isFlashOn = true);
      }

      setState(() {});
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
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      setState(() => hasPermission = false);
    }
  }

  Future<void> _processScanneddata(String? data) async {
    if (data == null) return;
    scannerController?.stop();

    final autoCopy = Hive.box('settings').get('autoCopy', defaultValue: false) as bool;
    if (autoCopy) {
      await Clipboard.setData(ClipboardData(text: data));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }

    String type = 'text';
    if (data.startsWith('BEGIN:VCARD')) {
      type = 'contact';
    } else if (data.startsWith('https://') || data.startsWith('http://')) {
      type = 'url';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text("Scanned Result:", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text("Type: ${type.toUpperCase()}",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(data, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 24),
                      if (type == 'url')
                        ElevatedButton.icon(
                          onPressed: () => _launchURL(data),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Open URL"),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        ),
                      if (type == 'contact')
                        ElevatedButton.icon(
                          onPressed: () => _saveContact(data),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Save Contact"),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => SharePlus.instance.share(ShareParams(text: data)),
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        scannerController?.start();
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Scan Again"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final historyBox = Hive.box<SavedCode>('scan_history');
    await historyBox.add(SavedCode(
      title: 'Scanned · ${DateTime.now().toLocal().toIso8601String()}',
      isQr: true,
    ));

    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _saveContact(String vcardData) async {
    final lines = vcardData.split('\n');
    String? name, phone, email;
    for (var line in lines) {
      if (line.startsWith('FN:')) name = line.substring(3);
      if (line.startsWith('TEL:')) phone = line.substring(4);
      if (line.startsWith('EMAIL:')) email = line.substring(5);
    }

    final contact = contacts.Contact()
      ..name.first = name ?? ''
      ..phones = [contacts.Phone(phone ?? '')]
      ..emails = [contacts.Email(email ?? '')];

    try {
      await contact.insert();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact Saved")));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission || scannerController == null) {
      return Scaffold(
        backgroundColor: Colors.indigo,
        appBar: AppBar(title: const Text("Scanner"), backgroundColor: Colors.indigo),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Camera Permission is required"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initScanner,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("Grant Permission"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.indigo,
      appBar: AppBar(
        title: const Text("Scan QR Code"),
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
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController!,
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue;
              if (code != null) _processScanneddata(code);
            },
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align QR Code within the frame',
                style: TextStyle(
                  color: Colors.white,
                  backgroundColor: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
