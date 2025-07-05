import 'package:flutter/material.dart';

import 'home_screen.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "QR Scanner",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
       primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(brightness: Brightness.light,
          seedColor: Colors.indigo
           )
      ),
      home: HomeScreen(),
    );
  }
}

