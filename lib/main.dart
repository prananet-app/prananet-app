import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: PranaNet(),
));

class PranaNet extends StatefulWidget {
  const PranaNet({super.key});
  @override
  State<PranaNet> createState() => _PranaNetState();
}

class _PranaNetState extends State<PranaNet> {
  int triage = 0;
  bool locked = false;
  String hosp = "";
  int timerSecs = 45 * 60;
  Timer? t;

  int pulse = 88;
  int spo2 = 98;
  String bp = "120/80";

  final hospitals = [
    {"name": "Apex Trauma Center", "dist": "2.9 km", "eta": "6m", "beds": 3, "vents": 2, "doc": "Neurosurgeon On-Site"},
    {"name": "Civil Super Speciality", "dist": "5.4 km", "eta": "12m", "beds": 5, "vents": 4, "doc": "Trauma Team Active"},
    {"name": "Lifeline Multi-Care", "dist": "8.1 km", "eta": "18m", "beds": 1, "vents": 1, "doc": "Intensivist On-Duty"},
  ];

  void lock(String name) {
    setState(() {
      locked = true;
      hosp = name;
      timerSecs = 45 * 60;
    });
    t?.cancel();
    t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSecs > 0) {
        setState(() => timerSecs--);
      } else {
        timer.cancel();
        setState(() => locked = false);
      }
    });
  }

  void openMaps(String target) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(target)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void editVitals() {
    final pC = TextEditingController(text: pulse.toString());
    final sC = TextEditingController(text: spo2.toString());
    final bC = TextEditingController(text: bp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "TRANSMIT IN-TRANSIT VITALS",
                style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Heart Rate / Pulse (BPM)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Oxygen SpO2 (%)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bC,
                decoration: const InputDecoration(
                  labelText: "Blood Pressure (e.g. 110/70)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      pulse = int.tryParse(pC.text) ?? pulse;
                      spo2 = int.tryParse(sC.text) ?? spo2;
                      bp = bC.text.isNotEmpty ? bC.text : bp;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("UPDATE & SEND TO DOCTOR", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String fmt(int s) => "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("PRANANET EMERGENCY", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (locked)
            Card(
              color: const Color(0xFF0E2A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF00E676))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(hosp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                        Text(fmt(timerSecs), style: const TextStyle(color: Color(0xFF00E676), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("PULSE: $pulse | SpO2: $spo2% | BP: $bp", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        InkWell(onTap: editVitals, child: const Text("EDIT >", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                        onPressed: () => openMaps(hosp),
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text("OPEN IN GOOGLE MAPS"),
                      ),
                    )
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text("SELECT EMERGENCY TYPE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              _triageBtn(0, "ROAD ACCIDENT", Colors.redAccent),
              const SizedBox(width: 6),
              _triageBtn(1, "HEART ATTACK", Colors.orangeAccent),
              const SizedBox(width: 6),
              _triageBtn(2, "BRAIN STROKE", Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 14),
          const Text("AVAILABLE ICU BEDS (LIVE)", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...hospitals.map((h) => Card(
            color: const Color(0xFF161B22),
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(h["name"].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      Text("${h["dist"]} (${h["eta"]})", style: const TextStyle(color: Color(0xFF00D2FF), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("${h["beds"]} ICU Beds | ${h["vents"]} Ventilators | ${h["doc"]}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white12,
                      ),
                      onPressed: locked ? null : () => lock(h["name"].toString()),
                      child: const Text("LOCK ICU BED (45 MINS)"),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _triageBtn(int idx, String title, Color c) {
    final sel = triage == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => triage = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? c.withOpacity(0.2) : const Color(0xFF161B22),
            border: Border.all(color: sel ? c : Colors.white10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: sel ? c : Colors.white60, fontSize: 8.5, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
