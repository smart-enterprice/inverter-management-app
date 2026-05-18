import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../feature/brand/model/brand_model.dart';
import '../../../widgets/circle_button.dart';
import '../controller/brand_controller.dart';

// ── Zoho Books design tokens ──────────────────────────────────────────────────
const _kP       = Color(0xFF185FA5);
const _kPBg     = Color(0xFFEBF4FF);
const _kPBd     = Color(0xFFBFD9F5);
const _kBg      = Color(0xFFF7F8FA);
const _kWhite   = Colors.white;
const _kBd      = Color(0xFFE5E7EB);
const _kT1      = Color(0xFF111827);
const _kT4      = Color(0xFF9CA3AF);
const _kRed     = Color(0xFFDC2626);
const _kRedBg   = Color(0xFFFEF2F2);
const _kRedBd   = Color(0xFFFECACA);

class BrandCreateScreen extends ConsumerStatefulWidget {
  const BrandCreateScreen({super.key});
  @override ConsumerState<BrandCreateScreen> createState() => _BrandCreateScreenState();
}

class _BrandCreateScreenState extends ConsumerState<BrandCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<TextEditingController> _modelCtrls = [];
  bool _loading = false;

  @override void initState() { super.initState(); _modelCtrls.add(TextEditingController()); }
  @override void dispose() { _nameCtrl.dispose(); _descCtrl.dispose();
  for (final c in _modelCtrls) {
    c.dispose();
  } super.dispose(); }

  void _addModel() => setState(() => _modelCtrls.add(TextEditingController()));
  void _removeModel(int i) => setState(() { _modelCtrls[i].dispose(); _modelCtrls.removeAt(i); });

  Future<void> _createBrand() async {
    if (!_formKey.currentState!.validate()) return;
    final models = _modelCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (models.toSet().length != models.length) { _snack('Duplicate model names are not allowed', _kRed); return; }
    setState(() => _loading = true);
    final error = await ref.read(brandControllerProvider.notifier).createBrand(
        BrandModel(brandName: _nameCtrl.text.trim(), description: _descCtrl.text.trim(), brandModels: models));
    await ref.read(brandControllerProvider.notifier).build();
    setState(() => _loading = false);
    if (!mounted) return;
    if (error != null) { _snack(error, _kRed); }
    else { _snack('Brand created successfully!', const Color(0xFF0F6E56)); Navigator.pop(context); }
  }

  void _snack(String msg, Color bg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bg, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    return Scaffold(backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [
          // ── App bar ──────────────────────────────────────────────────────
          Container(color: _kWhite,
              padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(context)),
                const Spacer(),
                Text('Create Brand', style: TextStyle(
                    fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700,
                    color: _kT1, letterSpacing: -0.2)),
                const Spacer(),
                SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
              ])),

          // ── Form ─────────────────────────────────────────────────────────
          Expanded(child: Form(key: _formKey,
              child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
                  child: Column(children: [
                    // Brand info
                    _Section(sw: sw, icon: Icons.storefront_outlined, title: 'Brand Info',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _lbl(sw, 'Brand Name'), SizedBox(height: sh * 0.006),
                          _field(sw, _nameCtrl, 'Enter brand name', Icons.label_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Brand name is required' : null),
                          SizedBox(height: sh * 0.015),
                          _lbl(sw, 'Description'), SizedBox(height: sh * 0.006),
                          _field(sw, _descCtrl, 'Enter brand description', Icons.description_outlined,
                              maxLines: 3,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null),
                        ])),
                    SizedBox(height: sh * 0.012),

                    // Models
                    _Section(sw: sw, icon: Icons.tag_rounded, title: 'Brand Models',
                        trailing: GestureDetector(onTap: _addModel,
                            child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: (sw * 0.03).clamp(10.0, 14.0),
                                    vertical: (sw * 0.01).clamp(3.0, 6.0)),
                                decoration: BoxDecoration(color: _kPBg, borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _kPBd, width: 0.5)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.add, size: (sw * 0.035).clamp(12.0, 16.0), color: _kP),
                                  SizedBox(width: sw * 0.01),
                                  Text('Add', style: TextStyle(
                                      fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w700, color: _kP)),
                                ]))),
                        child: Column(children: [
                          ..._modelCtrls.asMap().entries.map((e) {
                            final i = e.key; final ctrl = e.value;
                            return Padding(
                                padding: EdgeInsets.only(bottom: i < _modelCtrls.length - 1 ? sh * 0.012 : 0),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    _lbl(sw, 'Model ${i + 1}'), SizedBox(height: sh * 0.006),
                                    _field(sw, ctrl, 'Enter model name', Icons.tag_rounded,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                                  ])),
                                  if (_modelCtrls.length > 1) ...[
                                    SizedBox(width: sw * 0.02),
                                    GestureDetector(onTap: () => _removeModel(i),
                                        child: Container(
                                            width: (sw * 0.1).clamp(36.0, 44.0), height: (sw * 0.1).clamp(36.0, 44.0),
                                            decoration: BoxDecoration(color: _kRedBg,
                                                borderRadius: BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0)),
                                                border: Border.all(color: _kRedBd, width: 0.5)),
                                            child: Icon(Icons.delete_outline_rounded,
                                                size: (sw * 0.045).clamp(15.0, 20.0), color: _kRed))),
                                  ],
                                ]));
                          }),
                        ])),
                    SizedBox(height: sh * 0.025),

                    // Submit
                    SizedBox(width: double.infinity, child: ElevatedButton(
                        onPressed: _loading ? null : _createBrand,
                        style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
                            disabledBackgroundColor: _kBd, disabledForegroundColor: _kT4,
                            padding: EdgeInsets.symmetric(vertical: sh * 0.018),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0))),
                            elevation: 0),
                        child: _loading
                            ? SizedBox(width: (sw * 0.05).clamp(16.0, 22.0), height: (sw * 0.05).clamp(16.0, 22.0),
                            child: const CircularProgressIndicator(color: _kWhite, strokeWidth: 2.5))
                            : Text('Create Brand', style: TextStyle(
                            fontSize: (sw * 0.04).clamp(13.0, 18.0), fontWeight: FontWeight.w700)))),
                  ])))),
        ])));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Widget _lbl(double sw, String text) => Text(text.toUpperCase(),
      style: TextStyle(fontSize: (sw * 0.028).clamp(9.5, 12.5),
          fontWeight: FontWeight.w700, color: _kT4, letterSpacing: 0.5));

  Widget _field(double sw, TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1, String? Function(String?)? validator}) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return TextFormField(controller: ctrl, maxLines: maxLines, validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1, fontWeight: FontWeight.w500),
        decoration: InputDecoration(hintText: hint,
            hintStyle: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
            prefixIcon: Icon(icon, color: _kT4, size: (sw * 0.045).clamp(15.0, 20.0)),
            filled: true, fillColor: _kBg,
            contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.04,
                vertical: maxLines > 1 ? sw * 0.035 : 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
                borderSide: const BorderSide(color: _kBd, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
                borderSide: const BorderSide(color: _kBd, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
                borderSide: const BorderSide(color: _kP, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
                borderSide: const BorderSide(color: _kRed)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
                borderSide: const BorderSide(color: _kRed, width: 1.5))));
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.sw, required this.icon, required this.title,
    required this.child, this.trailing});
  final double sw; final IconData icon; final String title;
  final Widget child; final Widget? trailing;

  @override Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(children: [
              Container(width: (sw * 0.075).clamp(26.0, 36.0), height: (sw * 0.075).clamp(26.0, 36.0),
                  decoration: BoxDecoration(color: _kBg,
                      borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0))),
                  child: Icon(icon, size: (sw * 0.04).clamp(14.0, 20.0), color: _kT1)),
              SizedBox(width: sw * 0.025),
              Expanded(child: Text(title, style: TextStyle(
                  fontSize: (sw * 0.035).clamp(12.0, 16.0), fontWeight: FontWeight.w700, color: _kT1))),
              if (trailing != null) trailing!,
            ])),
        Divider(height: 1, color: _kBd),
        Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
      ]));
}