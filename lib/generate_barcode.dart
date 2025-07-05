import 'dart:io';

import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class GenerateBarcode extends StatefulWidget {
  const GenerateBarcode({super.key});

  @override
  State<GenerateBarcode> createState() => _GenerateBarcodeState();
}

class _GenerateBarcodeState extends State<GenerateBarcode> {
  final TextEditingController _textController =TextEditingController();
  final ScreenshotController _screenshotController= ScreenshotController();



  Future<void> _shareQRCode() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/bar_code.png';
    final capture = await _screenshotController.capture();
    if (capture == null) return null;

    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(capture);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath)],
        text: 'Share a OR Code',
      ),
    );
    //await Share.shareXFiles([XFile(imagePath)], text: "Share a OR Code");
  }

  String _barcodeData= '1234567890';
  int _selectedBarcodeIndex=0;
  final List<BarcodeOption> _barcodeTypes= [
    BarcodeOption('Code 128', Barcode.code128()),
    BarcodeOption('Code 39', Barcode.code39()),
    BarcodeOption('Code 93', Barcode.code93()),
    BarcodeOption('EAN-13', Barcode.ean8()),
    BarcodeOption('EAN-8', Barcode.upcA()),
    BarcodeOption('UPC-E', Barcode.upcA()),
    BarcodeOption('QR Code', Barcode.qrCode()),
    BarcodeOption('Data Matrix', Barcode.dataMatrix()),
    BarcodeOption('PDF417', Barcode.pdf417()),
  ];


  Barcode get _selectedBarcodeType=>
      _barcodeTypes[_selectedBarcodeIndex].barcode;

  void _generateBarCode(){
    setState(() {
      _barcodeData= _textController.text.isEmpty
          ? "123456789"
          : _textController.text;
    });
  }

  void _copyToClipboard(){
    Clipboard.setData(ClipboardData(text: _barcodeData));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Barcode Copied")));
  }

  Widget _buildBarcodeWidget(){
    try{
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:  Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0,3),
            ),
          ],
        ),
        child: BarcodeWidget(
          data: _barcodeData,
          barcode: _selectedBarcodeType,
        width: 300,
         height: 170,
        style: TextStyle(fontSize: 12),
        errorBuilder:(context,error){
            return Container(
              padding: EdgeInsets.all(16),

              child: Column(
                children: [
                  Icon(Icons.error,
                    color: Colors.redAccent,
                    size: 48,),
                  SizedBox(height: 8,),
                  Text("Invalid data for selected Barcode Type",style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,

                  ),
                  ),
                  SizedBox(height: 4),
                  Text(error.toString(),
                    style: TextStyle(color: Colors.redAccent.shade700, fontSize: 12),
                    textAlign: TextAlign.center,)
                  ,
                ],
              ),
            );
        } ,),
      );
    } catch(e){
      return Container();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Generator'),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        ),
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
                        color:  Colors.blue.shade800,
                      ),
                      ),
                      SizedBox(height: 16,),
                      TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          labelText: "Barcode Data",
                          hintText: 'Enter Product Data, SKU or Code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefix: Icon(Icons.qr_code,),
                          suffixIcon: IconButton(onPressed: (){
                            setState(() {
                              _textController.clear();
                            });
                          }, icon: Icon(Icons.clear))
                        ),
                        onChanged: (value)=> _generateBarCode(),
                      ),
                      SizedBox(height: 16,),
                      Text("Barcode Type",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:  Colors.blue.shade800,
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
                                items: _barcodeTypes.asMap().entries.map((entry){
                                  return DropdownMenuItem<int>(
                                    value: entry.key,
                                      child: Text(entry.value.name,
                                  ));
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
              SizedBox(height:24 ,),
              Card(
                color: Colors.white,
                elevation: 4,
                child: Padding(padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Generated Barcode",style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),),
                          IconButton(onPressed: _copyToClipboard,
                              icon: Icon(Icons.copy)),
                          IconButton(onPressed: (){

                          }, icon: Icon(Icons.share))
                        ],
                      ),
                      SizedBox(height: 16,),
                      _buildBarcodeWidget(),
                      SizedBox(height: 16,),
                      Container(

                      )
                    ],
                  ),
                ),
              )
            ],
          ),
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
