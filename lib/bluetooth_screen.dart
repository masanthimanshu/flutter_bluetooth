import "package:flutter/material.dart";
import "package:flutter_blue_plus/flutter_blue_plus.dart";
import "package:flutter_bluetooth/wifi_screen.dart";

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final List<ScanResult> _btDeviceList = [];

  Future<void> _setupScanListener() async {
    Set<String> temp = {};

    FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult res in results) {
        if (res.advertisementData.advName.isNotEmpty &&
            temp.add(res.advertisementData.advName)) {
          setState(() => _btDeviceList.add(res));
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _setupScanListener().then((_) async {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Results")),
      body: ListView.builder(
        itemCount: _btDeviceList.length,
        itemBuilder: (e, index) {
          return TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WifiScreen(target: _btDeviceList[index]),
              ),
            ),
            child: Text(_btDeviceList[index].advertisementData.advName),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
