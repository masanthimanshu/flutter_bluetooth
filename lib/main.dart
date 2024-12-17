import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

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

  final List<DropdownMenuItem<String>> _ssidList = [
    DropdownMenuItem(value: "Select SSID", child: Text("Select SSID")),
  ];

  String _ssid = "Select SSID";
  String _pass = "";

  Future<void> _permissionHandler() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await WiFiScan.instance.canStartScan(askPermissions: true);
  }

  void _scanWifi() async {
    Set<String> temp = {};

    WiFiScan.instance.onScannedResultsAvailable.listen((res) {
      for (WiFiAccessPoint accessPoint in res) {
        if (accessPoint.ssid.isNotEmpty && temp.add(accessPoint.ssid)) {
          _ssidList.add(DropdownMenuItem(
            value: accessPoint.ssid,
            child: Text(accessPoint.ssid),
          ));
        }
      }

      setState(() {});
    });
  }

  void _setupScanListener() {
    FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult res in results) {
        if (res.advertisementData.advName == "Scoobies Penguin") {
          debugPrint("Found our ESP32!");
          debugPrint("Device Id - ${res.device.remoteId.str}");
          debugPrint("Device Name - ${res.advertisementData.advName}");

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Device Connected Successfully")),
          );

          FlutterBluePlus.stopScan();

          await res.device.connect();
          final services = await res.device.discoverServices();
          targetCharacteristic = services.last.characteristics.last;
        }
      }
    });
  }

  Future<void> _sendData(String data) async {
    if (targetCharacteristic != null) {
      List<int> bytes = utf8.encode(data);
      await targetCharacteristic!.write(bytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data Sent Successfully")),
      );
    } else {
      debugPrint("Characteristic not found");
    }
  }

  @override
  void initState() {
    super.initState();
    _permissionHandler();

    _scanWifi();
    _setupScanListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Bluetooth")),
      body: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          DropdownButton(
            value: _ssid,
            items: _ssidList,
            onChanged: (text) => setState(() => _ssid = text!),
          ),
          SizedBox(height: 10),
          TextField(
            onChanged: (text) => _pass = text,
            decoration: InputDecoration(hintText: "Password"),
          ),
          SizedBox(height: 25),
          ElevatedButton(
            onPressed: () => _sendData("$_ssid +=+ $_pass"),
            child: Text("Send Data"),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Trying to connect .....")),
          );

          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
        },
        child: const Icon(Icons.bluetooth),
      ),
    );
  }
}
