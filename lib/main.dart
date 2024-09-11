import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothCharacteristic? targetCharacteristic;

  Future<void> _permissionHandler() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  void _setupScanListener() {
    FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult res in results) {
        if (res.advertisementData.advName == "Scoobies Penguin") {
          debugPrint("Found our ESP32!");
          debugPrint("Device Id - ${res.device.remoteId.str}");
          debugPrint("Device Name - ${res.advertisementData.advName}");

          FlutterBluePlus.stopScan();

          await res.device.connect();
          final services = await res.device.discoverServices();
          targetCharacteristic = services.last.characteristics.last;
        }
      }
    });
  }

  Future<void> _startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
  }

  Future<void> _sendData(String data) async {
    if (targetCharacteristic != null) {
      List<int> bytes = utf8.encode(data);
      await targetCharacteristic!.write(bytes);
      debugPrint('Data sent: $data');
    } else {
      debugPrint('Characteristic not found');
    }
  }

  @override
  void initState() {
    super.initState();
    _permissionHandler();
    _setupScanListener();

    Future.delayed(const Duration(seconds: 3)).then((_) => _startScan());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP Bluetooth")),
      body: const Center(child: Text("ESP Bluetooth")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _sendData("GWN14 +=+ tbm0htr1"),
        child: const Icon(Icons.bluetooth),
      ),
    );
  }
}
