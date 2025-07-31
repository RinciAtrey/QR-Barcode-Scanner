import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_barcode/utils/constants/colors.dart';

import '../../ads/ad_helper.dart';
import '../../ads/ad_units.dart';
import '../../data/camera_data.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');

    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(
        keys: ['isDarkMode', 'autoFlash', 'autoCopy'],
      ),
      builder: (context, settingsBox, _) {
        final isDark = settingsBox.get('isDarkMode', defaultValue: false) as bool;
        final autoFlash = settingsBox.get('autoFlash', defaultValue: false) as bool;
        final autoCopy = settingsBox.get('autoCopy', defaultValue: false) as bool;

        return Scaffold(
          appBar: AppBar(
              title: const Text('Settings', style: TextStyle(color: AppColors.appColour, fontWeight: FontWeight.bold),),
            centerTitle: true,

          ),
          body: Stack(
            children:[ Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                   ListTile(
                     title: Text('Camera'),
                subtitle: ValueListenableBuilder<Box>(
                  valueListenable: Hive.box('settings').listenable(keys: ['cameraFacing']),
                  builder: (_, box, __) {
                    final k = box.get('cameraFacing',
                        defaultValue: CameraFacingOption.back.key) as String;
                    final choice = CameraFacingOptionX.fromKey(k);
                    return Text(
                      choice == CameraFacingOption.back ? 'Back Camera' : 'Front Camera',
                      style: TextStyle(fontSize: 10),
                    );
                  },
                ),
                     trailing: Icon(Icons.arrow_forward_ios),
                     onTap: (){
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (_) => const CameraSettingsPage()),
                       );
                     }
                   ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: isDark,
                    onChanged: (val) {
                      settingsBox.put('isDarkMode', val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-Flash'),
                    value: settingsBox.get('autoFlash', defaultValue: false) as bool,
                    onChanged: (val) => settingsBox.put('autoFlash', val),
                  ),

                  SwitchListTile(
                    title: const Text('Auto-Copy'),
                    subtitle: const Text('Copy scan results to clipboard immediately'),
                    value: settingsBox.get('autoCopy', defaultValue: false) as bool,
                    onChanged: (val){
                      settingsBox.put('autoCopy', val);
                      debugPrint('autoFlash is now ${settingsBox.get('autoFlash')}');
                    }
                  ),

                ],
              ),
            ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AdaptiveBannerAd(adUnitId: AdUnits.banner),
              ),
        ]
          ),
        );
      },
    );
  }
}



class CameraSettingsPage extends StatelessWidget {
  const CameraSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');
    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(keys: ['cameraFacing']),
      builder: (_, settingsBox, __) {
        final currentKey = settingsBox.get(
            'cameraFacing',
            defaultValue: CameraFacingOption.back.key) as String;
        final current = CameraFacingOptionX.fromKey(currentKey);

        return Scaffold(
          appBar: AppBar(title: const Text('Camera')),
          body: ListView(
            children: CameraFacingOption.values.map((opt) {
              final label = opt == CameraFacingOption.back
                  ? 'Back Camera'
                  : 'Front Camera';
              return RadioListTile<CameraFacingOption>(
                title: Text(label),
                value: opt,
                groupValue: current,
                onChanged: (sel) {
                  if (sel == null) return;
                  settingsBox.put('cameraFacing', sel.key);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
