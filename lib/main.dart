import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() { runApp(const NeuroApp()); }

class NeuroApp extends StatelessWidget {
  const NeuroApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEURO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: const ColorScheme.dark(primary: Color(0xFF7C3AED), surface: Color(0xFF0F0C29)), useMaterial3: true),
      home: const ReportPage(),
    );
  }
}

class ReportParser {
  static int findQty(List<String> lines, List<String> keywords) {
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if (keywords.any((k) => l.contains(k.toLowerCase()))) {
        for (int j = i+1; j < lines.length && j < i+8; j++) {
          final n = lines[j].trim().replaceAll(RegExp(r'[^\d]'), '');
          if (n.isNotEmpty && n.length <= 4) {
            final v = int.tryParse(n);
            if (v != null && v > 0 && v < 9999) return v;
          }
        }
      }
    }
    return 0;
  }

  static String findCash(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('cash in drawer')) {
        for (int j = i+1; j < lines.length && j < i+6; j++) {
          final l = lines[j].trim();
          if (RegExp(r'\d+[\s,\.]\d+').hasMatch(l)) return l;
        }
      }
    }
    return '0';
  }

  static Map<String,String> parse(String raw) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final hot = findQty(lines, ['hot drinks']) + findQty(lines, ['hot chocolate']);
    final add = findQty(lines, ['extras bev']);
    final intenso = findQty(lines, ["l'aroma's intenso", 'intenso']);
    final ferdd = findQty(lines, ['freddoccinos', 'ice mixt']);
    final frappes = findQty(lines, ['frappes fusion']);
    final matcha = findQty(lines, ['matcha sweet']);
    final coffee = findQty(lines, ["l'aroma's coffee"]);
    final coke = findQty(lines, ['fizzy drinks']);
    final juice = findQty(lines, ['fresh juices']);
    final smooth = findQty(lines, ['fruit chillers']) + findQty(lines, ['smoothies']);
    final choc = findQty(lines, ['chooclet']);
    final muffins = findQty(lines, ['muffins']);
    final dessert = findQty(lines, ['dessert']);
    final tart = findQty(lines, ['tart psc']) + findQty(lines, ['mini pastry']);
    final clubs = findQty(lines, ["l'aroma's clubs"]);
    final wrap = findQty(lines, ['wrap']);
    final baker = findQty(lines, ['bakery']);
    final integrale = findQty(lines, ['integrale']);
    final pizza = findQty(lines, ['pizza']) + findQty(lines, ['mini pizza']);
    final croque = findQty(lines, ['croque']);
    final panini = findQty(lines, ['panini']);
    final petit = findQty(lines, ['petit pain']);
    final ciab = findQty(lines, ['ciabatta']);
    final salads = findQty(lines, ['salads']);
    final cash = findCash(lines);

    final msg1 = 'Hot: $hot\nAdd: $add\nIntenso: $intenso\nFerddoccinoceix: $ferdd\nFrappes: $frappes\nMatcha Sweet: $matcha\nCoffee beans: $coffee\nBoba: 0\nCoke& water: $coke\nFresh juices: $juice\nSmoothies&chillers: $smooth\nchooclet: $choc\nMuffins: $muffins\nM.O: 0\nDessert: $dessert\nM.o: 0\nBox dessert: $tart\nM.o: 0\nClubs: $clubs\nM.o: 0\nWrap: $wrap\nM.o: 0\nBaker: $baker\nM.o: 0\nPansarotti: 0\nBrow bea: $integrale\nM.o: 0\nPizza&mini: $pizza\nm.o: 0\nZee croque: $croque\nM.o: 0\nPanini: $panini\nM.o: 0\nPetite pain: $petit\nM.o: 0\nCiabat: $ciab\nM.o: 0\nSalads: $salads\nM.O: 0\nTotal sales: $cash\nmo: 0\nTotal: 0\nTotal percentage: 0';

    final msg2 = 'Hot drink: $hot\nCold Drin: ${ferdd+frappes+smooth}\nSoft Drin: $coke\nIntenso: $intenso\nDessert: $dessert\nSandwich: ${ciab+petit+panini+croque+integrale}\nSalad: $salads\nBakery: $baker\nTart: $tart\nSales: $cash';

    return {'msg1': msg1, 'msg2': msg2};
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  File? _image;
  bool _loading = false;
  String? _msg1, _msg2, _error, _rawText;
  bool _copied1 = false, _copied2 = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 100);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _loading = true; _msg1 = null; _msg2 = null; _error = null; _rawText = null; });
    try {
      final rec = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await rec.processImage(InputImage.fromFile(_image!));
      await rec.close();
      _rawText = result.text;
      if (result.text.trim().isEmpty) { setState(() { _error = 'مش قادر يقرأ الصورة، جرب صورة أوضح'; _loading = false; }); return; }
      final parsed = ReportParser.parse(result.text);
      setState(() { _msg1 = parsed['msg1']; _msg2 = parsed['msg2']; _loading = false; });
    } catch (e) { setState(() { _error = 'خطأ: $e'; _loading = false; }); }
  }

  Future<void> _copy(String text, bool first) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() { if (first) _copied1 = true; else _copied2 = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { if (first) _copied1 = false; else _copied2 = false; });
  }

  Future<void> _copyRaw() async {
    if (_rawText != null) await Clipboard.setData(ClipboardData(text: _rawText!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const SizedBox(height: 20),
        const Text('NEURO', style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFFA78BFA), letterSpacing: 8)),
        const Text('Editor: Hazem Sayed', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, constraints: const BoxConstraints(minHeight: 140, maxHeight: 260),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: _image != null ? const Color(0xFF22D3EE) : const Color(0xFF4C4A7A), width: 2), color: Colors.white.withOpacity(0.04)),
          child: _image != null ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_image!, fit: BoxFit.contain))
              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('📄', style: TextStyle(fontSize: 40)), Text('اختر صورة الريبورت', style: TextStyle(color: Color(0xFF64748B)))]),
        ),
        const SizedBox(height: 14),
        _btn('📷 كاميرا', () => _pick(ImageSource.camera), true),
        const SizedBox(height: 10),
        _btn('🖼️ معرض الصور', () => _pick(ImageSource.gallery), false),
        if (_loading) const Padding(padding: EdgeInsets.all(20), child: Column(children: [CircularProgressIndicator(color: Color(0xFFA78BFA)), SizedBox(height: 12), Text('⏳ بيقرأ الريبورت...', style: TextStyle(color: Color(0xFFA78BFA)))])),
        if (_error != null) Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.4))), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        if (_msg1 != null) ...[
          const SizedBox(height: 20),
          _card('✅ الرسالة الأولى', _msg1!, const Color(0xFFA78BFA), _copied1, () => _copy(_msg1!, true)),
          const SizedBox(height: 16),
          _card('📊 الرسالة التانية', _msg2!, const Color(0xFF22D3EE), _copied2, () => _copy(_msg2!, false)),
          const SizedBox(height: 16),
          GestureDetector(onTap: _copyRaw, child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))), child: const Text('📋 نسخ النص الخام (للتشخيص)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12)))),
        ],
        const SizedBox(height: 20),
      ]))),
    );
  }

  Widget _btn(String label, VoidCallback onTap, bool gradient) => GestureDetector(onTap: onTap, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: gradient ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]) : null, borderRadius: BorderRadius.circular(12), border: gradient ? null : Border.all(color: const Color(0xFF4C4A7A)), color: gradient ? null : Colors.white.withOpacity(0.04)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: gradient ? Colors.white : const Color(0xFFA78BFA), fontSize: 15, fontWeight: FontWeight.w700))));

  Widget _card(String title, String text, Color color, bool copied, VoidCallback onCopy) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)), GestureDetector(onTap: onCopy, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: copied ? color : color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(copied ? '✓ اتنسخ!' : 'نسخ', style: TextStyle(color: copied ? Colors.black : color, fontSize: 12, fontWeight: FontWeight.w700))))]), const SizedBox(height: 12), Text(text, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.8, fontFamily: 'monospace'))]));
}
