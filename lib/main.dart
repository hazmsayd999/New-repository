import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

class GeminiService {
  static const _key = 'AIzaSyAb8RN6JvDa2uNbkASMGaKHkTTpY6wJzA6AfTKvaBIU8d8uBEHQ';
  static const _url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<Map<String,String>> analyzeReport(File image) async {
    final bytes = await image.readAsBytes();
    final b64 = base64Encode(bytes);

    final prompt = '''هذه صورة Daily Financial Report. استخرج البيانات وأعطني رسالتين بالضبط:

رسالة 1:
Hot: [عدد Hot Drinks + Hot Chocolate]
Add: [Extras Bev]
Intenso: [L'aroma's Intenso]
Ferddoccinoceix: [Freddoccinos & Ice Mixt]
Frappes: [Frappes Fusion]
Matcha Sweet: [Matcha Sweet]
Coffee beans: [L'aroma's Coffee]
Boba: 0
Coke& water: [Fizzy Drinks]
Fresh juices: [Fresh Juices]
Smoothies&chillers: [Smoothies + Fruit Chillers]
chooclet: [Chooclet]
Muffins: [Muffins]
M.O: 0
Dessert: [Dessert]
M.o: 0
Box dessert: [Tart Psc + Mini Pastry]
M.o: 0
Clubs: [L'aroma's Clubs]
M.o: 0
Wrap: [Wrap]
M.o: 0
Baker: [Bakery]
M.o: 0
Pansarotti: 0
Brow bea: [Integrale]
M.o: 0
Pizza&mini: [Pizza + Mini Pizza]
m.o: 0
Zee croque: [Croque]
M.o: 0
Panini: [Panini]
M.o: 0
Petite pain: [Petit Pain]
M.o: 0
Ciabat: [Ciabatta]
M.o: 0
Salads: [Salads]
M.O: 0
Total sales: [Cash in drawer Amount]
mo: 0
Total: 0
Total percentage: 0

رسالة 2:
Hot drink: [Hot Drinks + Hot Chocolate]
Cold Drin: [Freddoccinos + Frappes + Smoothies]
Soft Drin: [Fizzy Drinks]
Intenso: [Intenso]
Dessert: [Dessert]
Sandwich: [Ciabatta + Petit Pain + Panini + Croque + Integrale]
Salad: [Salads]
Bakery: [Bakery]
Tart: [Tart Psc + Mini Pastry]
Sales: [Cash in drawer Amount]

أعطني فقط الرسالتين بدون أي كلام تاني. افصل بينهم بـ ---''';

    final body = jsonEncode({
      'contents': [{
        'parts': [
          {'text': prompt},
          {'inline_data': {'mime_type': 'image/jpeg', 'data': b64}}
        ]
      }]
    });

    final res = await http.post(
      Uri.parse('$_url?key=$_key'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
      final parts = text.split('---');
      return {
        'msg1': parts[0].trim(),
        'msg2': parts.length > 1 ? parts[1].trim() : '',
      };
    } else {
      throw Exception('خطأ: ${res.statusCode} - ${res.body}');
    }
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
  String? _msg1, _msg2, _error;
  bool _copied1 = false, _copied2 = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 95);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _loading = true; _msg1 = null; _msg2 = null; _error = null; });
    try {
      final result = await GeminiService.analyzeReport(_image!);
      setState(() { _msg1 = result['msg1']; _msg2 = result['msg2']; _loading = false; });
    } catch (e) {
      setState(() { _error = 'خطأ: $e'; _loading = false; });
    }
  }

  Future<void> _copy(String text, bool first) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() { if (first) _copied1 = true; else _copied2 = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { if (first) _copied1 = false; else _copied2 = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const SizedBox(height: 20),
        const Text('NEURO', style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFFA78BFA), letterSpacing: 8)),
        const Text('Editor: Hazem Sayed', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
        const Text('Daily Report Generator — v1.3', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
        if (_loading) const Padding(padding: EdgeInsets.all(20), child: Column(children: [CircularProgressIndicator(color: Color(0xFFA78BFA)), SizedBox(height: 12), Text('⏳ Gemini بيحلل الريبورت...', style: TextStyle(color: Color(0xFFA78BFA)))])),
        if (_error != null) Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.4))), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        if (_msg1 != null) ...[
          const SizedBox(height: 20),
          _card('✅ الرسالة الأولى', _msg1!, const Color(0xFFA78BFA), _copied1, () => _copy(_msg1!, true)),
          const SizedBox(height: 16),
          _card('📊 الرسالة التانية', _msg2!, const Color(0xFF22D3EE), _copied2, () => _copy(_msg2!, false)),
        ],
        const SizedBox(height: 20),
      ]))),
    );
  }

  Widget _btn(String label, VoidCallback onTap, bool gradient) => GestureDetector(onTap: onTap, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: gradient ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]) : null, borderRadius: BorderRadius.circular(12), border: gradient ? null : Border.all(color: const Color(0xFF4C4A7A)), color: gradient ? null : Colors.white.withOpacity(0.04)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: gradient ? Colors.white : const Color(0xFFA78BFA), fontSize: 15, fontWeight: FontWeight.w700))));

  Widget _card(String title, String text, Color color, bool copied, VoidCallback onCopy) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)), GestureDetector(onTap: onCopy, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: copied ? color : color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(copied ? '✓ اتنسخ!' : 'نسخ', style: TextStyle(color: copied ? Colors.black : color, fontSize: 12, fontWeight: FontWeight.w700))))]), const SizedBox(height: 12), Text(text, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.8, fontFamily: 'monospace'))]));
}
