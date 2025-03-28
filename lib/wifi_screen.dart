import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key, required this.target});

  final ScanResult target;

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  BluetoothCharacteristic? targetCharacteristic;

  final List<DropdownMenuItem<String>> _ssidList = [
    DropdownMenuItem(value: "Select SSID", child: Text("Select SSID")),
  ];

  String _ssid = "Select SSID";
  String _pass = "";

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

  Future<void> _getTarget() async {
    await widget.target.device.connect();
    final services = await widget.target.device.discoverServices();
    for (BluetoothService service in services) {
      final characteristics = service.characteristics;
      for (BluetoothCharacteristic characteristic in characteristics) {
        final charID = characteristic.characteristicUuid.str;
        if (charID == "ff01") {
          targetCharacteristic = characteristic;
        }
      }
    }
  }

  Future<void> _sendData(Map<String, String> data) async {
    String payload = jsonEncode(data);

    if (targetCharacteristic != null) {
      await targetCharacteristic!.write(utf8.encode(payload));

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
    _scanWifi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.target.advertisementData.advName)),
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
            onPressed: () => _sendData({"ssid": _ssid, "pwd": _pass}),
            child: Text("Send Data"),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getTarget,
        child: Icon(Icons.bluetooth),
      ),
    );
  }
}
