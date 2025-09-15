import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  bool _hidePass = true;

  Future<void> _getTarget() async {
    await widget.target.device.connect();
    final services = await widget.target.device.discoverServices();
    for (BluetoothService service in services) {
      final characteristics = service.characteristics;
      for (BluetoothCharacteristic characteristic in characteristics) {
        final charID = characteristic.characteristicUuid.str;
        if (charID == "ff01") targetCharacteristic = characteristic;
      }
    }
  }

  Future<void> _getWifiSsid() async {
    Set<String> temp = {};

    await targetCharacteristic!.setNotifyValue(true);

    targetCharacteristic!.lastValueStream.listen((val) {
      final res = jsonDecode(utf8.decode(val));

      if (temp.add(res["ssid"])) {
        setState(() {
          _ssidList.add(
            DropdownMenuItem(value: res["ssid"], child: Text(res["ssid"])),
          );
        });
      }
    });

    await targetCharacteristic!.write(utf8.encode("RefreshWifi"));
  }

  Future<void> _sendData() async {
    targetCharacteristic!.lastValueStream.listen((val) {
      final res = jsonDecode(utf8.decode(val));

      if (res["wifi"] == "connected") {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device Connected Successfully")),
        );
      }
    });

    await targetCharacteristic!.write(utf8.encode(
      jsonEncode({"ssid": _ssid, "pwd": _pass}),
    ));
  }

  @override
  void initState() {
    super.initState();
    _getTarget().then((_) => _getWifiSsid());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.target.advertisementData.advName)),
      body: _ssidList.length < 2
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(50),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton(
                        value: _ssid,
                        items: _ssidList,
                        onChanged: (text) => setState(() => _ssid = text!),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      obscureText: _hidePass,
                      onChanged: (text) => _pass = text,
                      decoration: InputDecoration(
                        hintText: "Enter Wifi Password",
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _hidePass = !_hidePass);
                          },
                          icon: Icon(
                            _hidePass ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _sendData,
                      child: Text("Send Data"),
                    ),
                  ]),
            ),
    );
  }
}
