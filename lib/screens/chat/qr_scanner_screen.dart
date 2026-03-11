import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final void Function(String code) onScanned;

  const QrScannerScreen({
    super.key,
    required this.onScanned,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Invite QR"),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;

          final code = capture.barcodes.first.rawValue;
          if (code == null || code.isEmpty) return;

          _handled = true;
          widget.onScanned(code);

          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}