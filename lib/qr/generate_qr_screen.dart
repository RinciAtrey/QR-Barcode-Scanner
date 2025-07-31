import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qr_barcode/ads/native_ad.dart';
import 'package:qr_barcode/qr/preview_qr_screen.dart';
import 'package:qr_barcode/qr/qr_ui.dart';
import '../ads/ad_helper.dart';
import '../ads/ad_units.dart';
import '../utils/constants/colors.dart';
import 'qr_code_type.dart';

class QrGeneratorScreen extends StatefulWidget {
  final CodeType initialType;
  const QrGeneratorScreen({super.key, this.initialType = CodeType.Text});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  late CodeType selectedType;
  BannerAd? _bannerAd;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  final TextEditingController _textEditingController = TextEditingController();
  String qrData = '';

  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'email': TextEditingController(),
    'url': TextEditingController(),
    'ssid': TextEditingController(),
    'wifipass': TextEditingController(),
    'call': TextEditingController(),
  };

  String _generateQRData() {
    switch (selectedType) {
      case CodeType.Contact:
        return '''BEGIN:VCARD
VERSION:3.0
FN:${_controllers['name']!.text}
TEL:${_controllers['phone']!.text}
EMAIL:${_controllers['email']!.text}
END:VCARD''';
      case CodeType.Website:
        String url = _controllers['url']!.text.trim();
        if (url.isEmpty) return '';
        if (!url.startsWith(RegExp(r'https?://'))) url = 'https://$url';
        return url;
      case CodeType.Wifi:
        final ssid = _controllers['ssid']!.text;
        final pass = _controllers['wifipass']!.text;
        return 'WIFI:S:$ssid;T:WPA;P:$pass;;';
      case CodeType.Call:
        final num = _controllers['call']!.text;
        return 'TEL:$num';
      case CodeType.Text:
      default:
        return _textEditingController.text;
    }
  }

  Map<String, String> _makeDisplayFields() {
    final m = <String, String>{};
    switch (selectedType) {
      case CodeType.Text:
        final t = _textEditingController.text.trim();
        if (t.isNotEmpty) m['Text'] = t;
        break;
      case CodeType.Website:
        var url = _controllers['url']!.text.trim();
        if (url.isNotEmpty) {
          if (!url.startsWith(RegExp(r'https?://'))) url = 'https://$url';
          m['URL'] = url;
        }
        break;
      case CodeType.Contact:
        final name  = _controllers['name']!.text.trim();
        final phone = _controllers['phone']!.text.trim();
        final email = _controllers['email']!.text.trim();
        if (name.isNotEmpty)  m['Name']  = name;
        if (phone.isNotEmpty) m['Phone'] = phone;
        if (email.isNotEmpty) m['Email'] = email;
        break;
      case CodeType.Wifi:
        final ssid = _controllers['ssid']!.text.trim();
        final pass = _controllers['wifipass']!.text.trim();
        if (ssid.isNotEmpty) m['SSID']     = ssid;
        if (pass.isNotEmpty) m['Password'] = pass;
        break;
      case CodeType.Call:
        final num = _controllers['call']!.text.trim();
        if (num.isNotEmpty) m['Number'] = num;
        break;
    }
    return m;
  }

  void _onFieldChanged(String _) {
    setState(() {
      _isValid = _formKey.currentState?.validate() ?? false;
      qrData  = _generateQRData();
    });
  }

  @override
  Widget build(BuildContext context) {
    late Widget formWidget;
    switch (selectedType) {
      case CodeType.Text:
        formWidget = TextForm(
          _textEditingController,
          _onFieldChanged,
        );
        break;
      case CodeType.Website:
        formWidget = UrlForm(
          _controllers['url']!,
          _onFieldChanged,
        );
        break;
      case CodeType.Contact:
        formWidget = ContactForm(
          {
            'name': _controllers['name']!,
            'email': _controllers['email']!,
            'phone': _controllers['phone']!,
          },
          _onFieldChanged,
        );
        break;
      case CodeType.Wifi:
        formWidget = WifiForm(
          _controllers['ssid']!,
          _controllers['wifipass']!,
          _onFieldChanged,
        );
        break;
      case CodeType.Call:
        formWidget = CallForm(
          _controllers['call']!,
          _onFieldChanged,
        );
        break;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.appColour,
      appBar: AppBar(
        backgroundColor: AppColors.appColour,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Generate QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold )),
        centerTitle: true,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor:   Colors.white,        //text color when enabled
              disabledForegroundColor: Colors.grey,   //text when disabled
            ),
            onPressed: _isValid
              ? () {
              final data = _generateQRData();
               if (data.isEmpty) return;
              final displayFields = _makeDisplayFields();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QRPreviewScreen(
                    title: selectedType.name,
                    data: data,
                    displayFields: displayFields,
                  ),
                ),
              );
            } : null,
            child: const Text(
              'Create',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: formWidget,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            NativeAds(),
            SizedBox(height: 8),
            AdaptiveBannerAd(adUnitId: AdUnits.banner),
          ],
        ),
      ),
    );
  }
}
