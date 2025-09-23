import 'package:flutter/material.dart';
import '../services/asl_service.dart';

class AslDemoScreen extends StatefulWidget { const AslDemoScreen({super.key}); @override State<AslDemoScreen> createState()=>_AslDemoScreenState(); }
class _AslDemoScreenState extends State<AslDemoScreen> {
  final _svc = MockAslService(); final _ctl = TextEditingController(); String? _asset; String? _fallback;
  @override Widget build(BuildContext c)=>Scaffold(
    appBar: AppBar(title: const Text('ASL Prototype')),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller:_ctl, decoration: const InputDecoration(labelText:'Enter text')),
      const SizedBox(height:12),
      ElevatedButton(onPressed: () async {
        if(_ctl.text.trim().isEmpty){ setState(()=>_fallback="(fallback) No text—show caption only"); return; }
        final a = await _svc.textToAsl(_ctl.text); setState((){ _asset=a; _fallback=null; });
      }, child: const Text('Convert to ASL')),
      const SizedBox(height:24),
      if(_asset!=null) Image.asset(_asset!, height:160),
      if(_fallback!=null) Text(_fallback!, style: const TextStyle(fontStyle: FontStyle.italic))
    ])));
}
