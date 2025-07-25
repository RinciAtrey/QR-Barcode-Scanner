import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:qr_barcode/screens/main_pages/scanner_screen.dart';
import 'package:qr_barcode/screens/main_pages/history_page.dart';
import 'package:qr_barcode/screens/main_pages/settings_page.dart';
import 'package:qr_barcode/utils/constants/colors.dart';
import 'package:qr_barcode/utils/theme/theme.dart';
import 'package:qr_barcode/utils/theme/theme_manager.dart';
import 'data/savedcode.dart';
import 'data/scannedcode.dart';
import 'screens/main_pages/my_codes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SavedCodeAdapter());
  await Hive.deleteBoxFromDisk('scan_history');
  await Hive.openBox<ScannedCode>('scan_history');
  await Hive.openBox<SavedCode>('saved_codes');
  Hive.registerAdapter(ScannedCodeAdapter());
  await Hive.openBox<ScannedCode>('scan_history');
  await Hive.openBox('settings');
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDarkMode']),
      builder: (context, Box settingsBox, _) {
        final isDark = settingsBox.get('isDarkMode', defaultValue: false) as bool;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'QR Barcode',
          theme: lightTheme.copyWith(
            textTheme: GoogleFonts.albertSansTextTheme(    //alexandriaTextTheme, albertSansTextTheme
            Theme.of(context).textTheme,
          ), ),
          darkTheme: darkTheme.copyWith(
            textTheme: GoogleFonts.albertSansTextTheme(
              Theme.of(context).textTheme,
            )
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: HomeScreen(key: HomeScreen.globalKey),
        );
      },
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static final GlobalKey<_HomeScreenState> globalKey = GlobalKey<_HomeScreenState>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _currentIndex = 0;

  void switchTo(int idx) => setState(() => _currentIndex = idx);

  final List<Widget> _screens = [
    const ScannerScreen(),
    const MyCodes(),        // stored codes+ codes making
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxWidth * 0.07;
          iconSize = iconSize.clamp(24.0, 30.0);
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedFontSize: 14,
            selectedItemColor: AppColors.appColour,
            unselectedItemColor: Colors.grey,
            unselectedFontSize: 12,
            iconSize: iconSize,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan',),
              BottomNavigationBarItem(
                icon: Icon(Icons.code),
                label: 'My Codes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }
}






