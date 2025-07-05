import 'package:flutter/material.dart';
import 'package:qr_barcode/generate_qr_screen.dart';
import 'package:qr_barcode/qr_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: SafeArea(child: Column(
        children: [
          SizedBox(height: 12,),
          Padding(
            padding: EdgeInsets.all(12),
          child: Text("QR Code Scanner",
            style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          ),
          SizedBox(height: 40),
          Center(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: Colors.black.withAlpha(2),
                   blurRadius: 10,
                  spreadRadius: 5
                ),]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildFeatureButton(
                    context,
                    "Generate QR Code",
                    Icons.qr_code_sharp,
                      ()=> Navigator.push(context, MaterialPageRoute(builder:(context)=>const QrGeneratorScreen()))
                  ),
                  SizedBox(height: 12),
                  _buildFeatureButton(
                      context,
                      "Scan QR Code",
                      Icons.qr_code_scanner,
                          ()=> Navigator.push(context, MaterialPageRoute(builder:(context)=>const QrScannerScreen()))
                  )
                ],
              ),
            )
          )
        ],
      ))
    );
  }
  Widget _buildFeatureButton(BuildContext context, String text, IconData icon, VoidCallback onPressed){
  return GestureDetector(
    onTap: onPressed,
    child: Container( //white border
      padding: EdgeInsets.all(15),
      height: 200,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(15)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, size:90, color: Colors.white,),
          Text(text, style: TextStyle( fontSize: 20, color: Colors.white),)
        ],
      ),
    ),
  );
  }
}
