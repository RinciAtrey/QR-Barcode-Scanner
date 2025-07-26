import 'package:flutter/material.dart';
import 'package:qr_barcode/barcode/generate_barcode.dart';
import 'package:qr_barcode/qr/generate_qr_screen.dart';

import '../qr/qr_code_type.dart';



class GenerateCode extends StatefulWidget {
  const GenerateCode({super.key});

  @override
  State<GenerateCode> createState() => _GenerateCodeState();
}

class _GenerateCodeState extends State<GenerateCode> {
  final DraggableScrollableController _sheetCtrl =
  DraggableScrollableController();


  @override
  Widget build(BuildContext context) {
    final _qrItems = [
      _TileData(
          icon: Icons.text_snippet,
          label: 'Text',
          action: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const QrGeneratorScreen(initialType: CodeType.Text),
            ));
          }
      ),
      _TileData(
          icon: Icons.person,
          label: 'Contact',
          action: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const QrGeneratorScreen(initialType: CodeType.Contact),
            ));
          }
      ),
      _TileData(
        icon: Icons.wifi,
        label: 'Wifi',
        action: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => QrGeneratorScreen(initialType: CodeType.Wifi),
          ));
        },
      ),
      _TileData(
        icon: Icons.web,
        label: 'Website',
        action: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const QrGeneratorScreen(initialType: CodeType.Website),
          ));
        },
      ),
      _TileData(icon: Icons.call, label: 'Call', action: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => QrGeneratorScreen(initialType: CodeType.Call),
        ));
      }),
    ];


    final _barItems = [
      _TileData(
        icon: Icons.qr_code_2_rounded,
        label: 'Code 128',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 0,)));
        },
      ),
      _TileData(
        icon: Icons.lock,
        label: 'Code 39',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 1,)));
        },
      ),
      _TileData(
        icon: Icons.lock,
        label: 'Code 93',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 2,)));
        },
      ),
      _TileData(
        icon: Icons.lock,
        label: 'EAN-13',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 3,)));
        },
      ),
      _TileData(
        icon: Icons.lock,
        label: 'EAN-8',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 4,)));
        },
      ),
      _TileData(
        icon: Icons.lock,
        label: 'UPC-E',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 5,)));
        },
      ),
      _TileData(
        icon: Icons.lock,
        label: 'Data Matrix',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 6,)));
        },
      ),
      _TileData(
        icon: Icons.lock,
        label: 'PDF417',
        action: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GenerateBarcode(initialIndex: 7,)));
        },
      ),

    ];

    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.95,
      // snap: true,
      // snapSizes: const [0.3, 0.75],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Generate Code',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),

              // QR Code Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text(
                    'QR code',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _CodeTile(
                      data: _qrItems[i],
                      onTap: _qrItems[i].action,
                    ),
                    childCount: _qrItems.length,
                  ),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                ),
              ),

              // Barcode Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Text(
                    'Barcode',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _CodeTile(
                      data: _barItems[i],
                      onTap: _barItems[i].action,
                    ),
                    childCount: _barItems.length,
                  ),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                ),
              ),

              // bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

class _TileData {
  final IconData icon;
  final String label;
  final VoidCallback action;
  const _TileData({
    required this.icon,
    required this.label,
    required this.action,
  });
}

class _CodeTile extends StatelessWidget {
  final _TileData data;
  final VoidCallback onTap;
  const _CodeTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, size: 28, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              data.label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
