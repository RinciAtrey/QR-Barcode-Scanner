import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');

    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(keys: ['isDarkMode']),
      builder: (context, settingsBox, _) {
        final isDark = settingsBox.get('isDarkMode', defaultValue: false) as bool;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
               ListTile(
                 title: Text('Camera'),
                 //subtitle: Text('Manage your settings here'),
                 trailing: Icon(Icons.arrow_forward_ios),
                 onTap: (){

                 }
               ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: isDark,
                onChanged: (val) {
                  settingsBox.put('isDarkMode', val);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
