import 'dart:io';

import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:barcode/barcode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_barcode/barcode/preview_barcode_screen.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../ads/ad_helper.dart';
import '../ads/ad_units.dart';
import '../ads/native_ad.dart';
import '../utils/constants/colors.dart';

class GenerateBarcode extends StatefulWidget {
  final int initialIndex;
  const GenerateBarcode({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<GenerateBarcode> createState() => _GenerateBarcodeState();
}

class _GenerateBarcodeState extends State<GenerateBarcode> {
  final TextEditingController _textController =TextEditingController();
  final ScreenshotController _screenshotController= ScreenshotController();
  late int _selectedBarcodeIndex;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedBarcodeIndex = widget.initialIndex;
    _barcodeData = _textController.text;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }



  String _barcodeData = '';
  final List<BarcodeOption> _barcodeTypes= [
    BarcodeOption('Code 128', Barcode.code128()),
    BarcodeOption('Code 39', Barcode.code39()),
    BarcodeOption('Code 93', Barcode.code93()),
    BarcodeOption('EAN-13', Barcode.ean8()),
    BarcodeOption('EAN-8', Barcode.upcA()),
    BarcodeOption('UPC-E', Barcode.upcA()),
    BarcodeOption('Data Matrix', Barcode.dataMatrix()),
    BarcodeOption('PDF417', Barcode.pdf417()),
  ];


  void _generateBarCode(){
    setState(() {
      _barcodeData = _textController.text;
    });

  }

  @override
  Widget build(BuildContext context) {
    final List<int> _allowedBarcodeIndices = [0, 6, 7];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.appColour,
      appBar: AppBar(
          backgroundColor: AppColors.appColour,
        foregroundColor: Colors.white,
        title: Text('Barcode Generator',style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold )),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              _generateBarCode();
              final displayFields = <String,String>{ 'Data': _barcodeData };
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PreviewBarcodeScreen(
                    type: _barcodeTypes[_selectedBarcodeIndex],
                    data: _barcodeData,
                    displayFields: displayFields,
                  ),
                ),
              );
            },
            child: const Text('Create', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.white,
                  elevation: 4,
                    child: Padding(padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Enter Product Data",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:  AppColors.appColour,
                        ),
                        ),
                        SizedBox(height: 16,),
                        TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: "eg. 123456789",
                            labelText: "Barcode Data",
                              errorText: _errorText,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(onPressed: (){
                              setState(() {
                                _textController.clear();
                                _barcodeData = '';
                              });
                            }, icon: Icon(Icons.clear))
                          ),
                          onChanged: (value) {
                            _generateBarCode();
                          },
                        ),
                        SizedBox(height: 16,),
                        Text("Barcode Type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:  AppColors.appColour,
                          ),
                        ),
                        SizedBox(height: 8,),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                  value: _selectedBarcodeIndex,
                                  icon: Icon(Icons.arrow_drop_down),
                                  items: _allowedBarcodeIndices.map((i) {
                                    return DropdownMenuItem<int>(
                                      value: i,
                                      child: Text(_barcodeTypes[i].name),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue){
                                  if(newValue!= null){
                                    setState(() {
                                      _selectedBarcodeIndex=newValue;
                                    });
                                  }
                                  })),
                        )
                      ],
                    ),),
                ),
              ],
            ),
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



class BarcodeOption {
  final String name;
  final Barcode barcode;

  BarcodeOption(this.name, this.barcode);
}
