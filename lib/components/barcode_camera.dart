// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatelessWidget {
  final ValueChanged<String> onBarcodeScanned;

  const BarcodeScannerWidget({Key? key, required this.onBarcodeScanned})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPopCalled = false; // Prevent multiple pops

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        backgroundColor: Colors.transparent,
      ),
      body: MobileScanner(
        controller: MobileScannerController(),
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue;

          if (code != null && !isPopCalled) {
            isPopCalled = true; // Prevent further pops
            onBarcodeScanned(code); // Trigger callback
            Navigator.of(context).pop(); // Close scanner
          }
        },
      ),
    );
  }
}
