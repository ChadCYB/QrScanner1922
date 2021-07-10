import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'dart:io';

void main() {
  runApp(MyApp());
}

const String app_title = '1922實聯制掃描器';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return new MaterialApp(
      title: app_title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(app_title),
          centerTitle: true,
          // actions: <Widget>[
          //   _threeItemPopup(),
          // ],
          // actions: <Widget>[
          //   IconButton(
          //     icon: const Icon(Icons.settings),
          //     tooltip: 'Setting',
          //     onPressed: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(content: Text('This is a snackbar')));
          //     },
          //   ),
          // ],
        ),
        body: QRScanPage());
  }

  Widget _threeItemPopup() => PopupMenuButton<int>(
        icon: const Icon(Icons.settings),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: Text("功能設定"),
            value: 1,
          ),
          PopupMenuDivider(
            height: 10,
          ),
          CheckedPopupMenuItem(
            child: Text(
              "掃描後自動關閉APP",
              style: TextStyle(color: Colors.black),
            ),
            value: 2,
            checked: false,
          ),
        ],
      );
}

class QRScanPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final qrKey = GlobalKey(debugLabel: 'QR');

  Barcode? barcode;
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() async {
    super.reassemble();

    if (Platform.isAndroid) {
      await controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          body: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              buildQrView(context),
              Positioned(top: 10, child: buildControlButtons()),
              Positioned(bottom: 20, child: buildResult()),
            ],
          ),
        ),
      );

  Widget buildControlButtons() => Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white24,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: FutureBuilder<bool?>(
              future: controller?.getFlashStatus(),
              builder: (context, snapshot) {
                if (snapshot.data != null) {
                  return Icon(
                      snapshot.data! ? Icons.flash_on : Icons.flash_off);
                } else {
                  return Container();
                }
              },
            ),
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {});
            },
          ),
          IconButton(
            icon: FutureBuilder(
                future: controller?.getCameraInfo(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return Icon(Icons.switch_camera);
                  } else {
                    return Container();
                  }
                }),
            onPressed: () async {
              await controller?.flipCamera();
              setState(() {});
            },
          ),
        ],
      ));

  Widget buildResult() => Container(
        padding: EdgeInsets.all(12),
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white54,
        ),
        child: Text(
          barcode != null ? getBarcodeStr() : '請將條碼至於框框內掃描',
          maxLines: 3,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      );

  Widget buildQrView(BuildContext context) => QRView(
        key: qrKey,
        onQRViewCreated: onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Theme.of(context).accentColor,
          borderRadius: 10,
          borderLength: 20,
          borderWidth: 10,
          cutOutSize: MediaQuery.of(context).size.width * 0.8,
        ),
      );

  _textMe(String textMsg) async {
    if (Platform.isAndroid) {
      await launch('sms:1922?body=${textMsg}');
      exit(0);
    } else if (Platform.isIOS) {
      // iOS
      await launch('sms:1922&body=${textMsg}');
      exit(0);
    } else {
      throw 'Could not launch uri';
    }
  }

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      setState(() {
        barcode = scanData;
        if (is1922Barcode()) {
          _textMe(getBarcodeStr());
        }
      });
    });
  }

  bool is1922Barcode() {
    return (barcode!.code.substring(0, 11).toUpperCase() == 'SMSTO:1922:');
  }

  String getBarcodeStr() {
    String barcode_str = '請將條碼至於框框內掃描';
    if (barcode != null) {
      if (is1922Barcode()) {
        barcode_str = barcode!.code.substring(11);
      } else {
        barcode_str = '請掃描正確的實聯制QR Code';
      }
    }
    return barcode_str;
  }
}
