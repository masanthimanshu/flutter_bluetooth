import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_blue_plus/flutter_blue_plus.dart";

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key, required this.target});

  final ScanResult target;

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  BluetoothCharacteristic? targetCharacteristic;

  final List<DropdownMenuItem<String>> _ssidList = [
    const DropdownMenuItem(value: "Select SSID", child: Text("Select SSID")),
  ];

  String _ssid = "Select SSID";
  String _pass = "";

  bool _hidePass = true;

  Future<void> _getTarget() async {
    await widget.target.device.connect(license: License.free);
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
      final res = jsonDecode(utf8.decode(val).replaceAll(r"\", ""));

      if (res["status"] == "ok") {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Device Connected - ${res["device_serial"]}"),
        ));
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
    if (_ssidList.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text("Looking for Wifi Ssid")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.target.advertisementData.advName)),
      body: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: double.infinity,
            child: DropdownButton(
              value: _ssid,
              items: _ssidList,
              onChanged: (text) => setState(() => _ssid = text!),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            obscureText: _hidePass,
            onChanged: (text) => _pass = text,
            decoration: InputDecoration(
              hintText: "Enter Wifi Password",
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePass = !_hidePass),
                icon: Icon(_hidePass ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: _sendData, child: const Text("Send Data")),
        ]),
      ),
    );
  }
}
