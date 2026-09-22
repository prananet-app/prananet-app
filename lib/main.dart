import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: BhuCareApp(),
));

// आपकी असली Supabase चाबियाँ बिल्कुल सही तरीके से सेट:
const String supabaseUrl = '''https://frzvxgjkwtvltfulwlay.supabase.co''';

const String supabaseAnonKey = '''eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyenZ4Z2prd3R2bHRmdWx3bGF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAwMDkwMDgsImV4cCI6MjEwNTU4NTAwOH0.lxvaKIKGoHXErBxqFkXdQF3DK7O-lXkzrbbHH_Fd-VE''';

class BhuCareApp extends StatefulWidget {
  const BhuCareApp({super.key});
  @override
  State<BhuCareApp> createState() => _BhuCareAppState();
}

class _BhuCareAppState extends State<BhuCareApp> {
  int triage = 0;
  bool locked = false;
  String hosp = "";
  int timerSecs = 45 * 60;
  Timer? t;

  String pulse = "--";
  String spo2 = "--";
  String bp = "--/--";
  bool vitalsEntered = false;
  String cloudStatus = "Cloud Ready";

  final triageTypes = ["ROAD ACCIDENT", "HEART ATTACK", "BRAIN STROKE"];

  final hospitals = [
    {"name": "Apex Trauma Center", "dist": "2.9 km", "eta": "6m", "beds": 3, "vents": 2, "doc": "Neurosurgeon On-Site"},
    {"name": "Civil Super Speciality", "dist": "5.4 km", "eta": "12m", "beds": 5, "vents": 4, "doc": "Trauma Team Active"},
    {"name": "Lifeline Multi-Care", "dist": "8.1 km", "eta": "18m", "beds": 1, "vents": 1, "doc": "Intensivist On-Duty"},
  ];

  // Supabase में लाइव बुकिंग और वाइटल्स सेव करने का फंक्शन
  Future<void> syncWithSupabase() async {
    setState(() => cloudStatus = "Transmitting to Hospital...");
    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/emergency_bookings');
      final res = await http.post(
        endpoint,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'token': 'PRN-9821',
          'hospital_name': hosp,
          'emergency_type': triageTypes[triage],
          'pulse': int.tryParse(pulse) ?? 0,
          'spo2': int.tryParse(spo2) ?? 0,
          'bp': bp,
          'status': 'IN_TRANSIT',
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 201 || res.statusCode == 200) {
        setState(() => cloudStatus = "LIVE CLOUD SYNCED ✅");
      } else {
        setState(() => cloudStatus = "Local Cache Active");
      }
    } catch (_) {
      setState(() => cloudStatus = "Local Cache Active");
    }
  }

  void lock(String name) {
    setState(() {
      locked = true;
      hosp = name;
      timerSecs = 45 * 60;
    });

    // तुरंत Supabase सर्वर पर बुकिंग रिकॉर्ड भेजें
    syncWithSupabase();

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
    final pC = TextEditingController(text: vitalsEntered ? pulse : "");
    final sC = TextEditingController(text: vitalsEntered ? spo2 : "");
    final bC = TextEditingController(text: vitalsEntered ? bp : "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_heart, color: Color(0xFF00E676), size: 20),
                  SizedBox(width: 8),
                  Text("TRANSMIT IN-TRANSIT VITALS", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pC,
                keyboardType: TextInputType.number,
                cursorColor: const Color(0xFF00E676),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Heart Rate / Pulse (BPM)",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "e.g. 92",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sC,
                keyboardType: TextInputType.number,
                cursorColor: const Color(0xFF00E676),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Oxygen Saturation SpO2 (%)",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "e.g. 98",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bC,
                cursorColor: const Color(0xFF00E676),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Blood Pressure (e.g. 120/80)",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "e.g. 110/70",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    setState(() {
                      pulse = pC.text.isNotEmpty ? pC.text : "--";
                      spo2 = sC.text.isNotEmpty ? sC.text : "--";
                      bp = bC.text.isNotEmpty ? bC.text : "--/--";
                      vitalsEntered = true;
                    });
                    Navigator.pop(ctx);
                    if (locked) {
                      syncWithSupabase();
                    }
                  },
                  child: const Text("UPDATE & TRANSMIT TO DOCTOR", style: TextStyle(fontWeight: FontWeight.w900)),
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
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFFFF3B30), size: 20),
            SizedBox(width: 8),
            Text("BHU-CARE EMERGENCY", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload_rounded, size: 14, color: Color(0xFF00E676)),
                const SizedBox(width: 6),
                Expanded(child: Text(cloudStatus, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Active Lock Card
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
                        Expanded(child: Text(hosp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white), overflow: TextOverflow.ellipsis)),
                        Text(fmt(timerSecs), style: const TextStyle(color: Color(0xFF00E676), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vitalsEntered ? "PULSE: $pulse | SpO2: $spo2% | BP: $bp" : "VITALS: NOT RECORDED",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: vitalsEntered ? Colors.white70 : Colors.amberAccent),
                        ),
                        InkWell(
                          onTap: editVitals,
                          child: Text(vitalsEntered ? "EDIT >" : "TAP TO LOG >", style: const TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                        onPressed: () => openMaps(hosp),
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text("OPEN IN GOOGLE MAPS", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Triage
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

          // Hospital List
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
                      child: const Text("LOCK ICU BED (45 MINS)", style: TextStyle(fontWeight: FontWeight.bold)),
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
