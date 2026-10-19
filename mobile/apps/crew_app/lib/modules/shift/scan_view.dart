import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans the ambulance QR and returns its token with `Get.back(result: token)`.
class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.ink,
        appBar: AppBar(title: Text('scan_title'.tr)),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final value = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                if (value == null || _done) return;
                _done = true;
                Get.back(result: value);
              },
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Space.xxl),
                  child: Text('camera_unavailable'.tr, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(Space.cardRadius)),
              ),
            ),
            Positioned(
              left: Space.screen,
              right: Space.screen,
              bottom: Space.xxl,
              child: Text('scan_hint'.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      );
}
