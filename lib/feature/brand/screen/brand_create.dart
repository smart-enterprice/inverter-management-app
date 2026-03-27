import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../../../widgets/circle_button.dart';
import '../controller/brand_controller.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue       = Color(0xFF1B4FD8);
const _kBlueBg     = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg         = Color(0xFFF2F4F8);
const _kCard       = Colors.white;
const _kBorder     = Color(0xFFE5E7EB);
const _kDark       = Color(0xFF111827);
const _kMuted      = Color(0xFF9CA3AF);
const _kRed        = Color(0xFFDC2626);
const _kRedBg      = Color(0xFFFEF2F2);
const _kRedBorder  = Color(0xFFFECACA);

class BrandCreateScreen extends ConsumerStatefulWidget {
  const BrandCreateScreen({super.key});

  @override
  ConsumerState<BrandCreateScreen> createState() => _BrandCreateScreenState();
}

class _BrandCreateScreenState extends ConsumerState<BrandCreateScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final List<TextEditingController> _modelCtrls = [];
  bool _isLoading        = false;

  @override
  void initState() {
    super.initState();
    _modelCtrls.add(TextEditingController()); // start with one model field
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _modelCtrls) c.dispose();
    super.dispose();
  }

  void _addModel() =>
      setState(() => _modelCtrls.add(TextEditingController()));

  void _removeModel(int i) {
    setState(() {
      _modelCtrls[i].dispose();
      _modelCtrls.removeAt(i);
    });
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _createBrand() async {
    if (!_formKey.currentState!.validate()) return;

    final models = _modelCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (models.toSet().length != models.length) {
      _showSnack('Duplicate model names are not allowed', _kRed);
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref
        .read(loadBrandsControllerProvider.notifier)
        .createBrand(BrandModel(
      brandName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      brandModels: models,
    ));

    await ref.read(loadBrandsControllerProvider.notifier).loadBrands();
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (error != null) {
      _showSnack(error, _kRed);
    } else {
      _showSnack('Brand created successfully!', Colors.green);
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Nav ────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Create Brand',
                      style: TextStyle(
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                          letterSpacing: -0.2)),
                  const Spacer(),
                  SizedBox(width: sw * 0.095),
                ],
              ),
            ),

            // ── Form ───────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding:
                  EdgeInsets.symmetric(horizontal: sw * 0.038),
                  child: Column(
                    children: [
                      // Brand Info card
                      _SectionCard(
                        sw: sw,
                        icon: Icons.storefront_outlined,
                        title: 'Brand Info',
                        children: [
                          _FieldLabel(sw: sw, label: 'Brand Name'),
                          SizedBox(height: sh * 0.006),
                          _FormField(
                            sw: sw,
                            ctrl: _nameCtrl,
                            hint: 'Enter brand name',
                            icon: Icons.label_outline_rounded,
                            validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Brand name is required'
                                : null,
                          ),
                          SizedBox(height: sh * 0.015),
                          _FieldLabel(sw: sw, label: 'Description'),
                          SizedBox(height: sh * 0.006),
                          _FormField(
                            sw: sw,
                            ctrl: _descCtrl,
                            hint: 'Enter brand description',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                            validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Description is required'
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(height: sh * 0.012),

                      // Models card
                      _SectionCard(
                        sw: sw,
                        icon: Icons.category_outlined,
                        title: 'Brand Models',
                        trailing: GestureDetector(
                          onTap: _addModel,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: sw * 0.03,
                                vertical: sw * 0.01),
                            decoration: BoxDecoration(
                              color: _kBlueBg,
                              borderRadius: BorderRadius.circular(20),
                              border:
                              Border.all(color: _kBlueBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: sw * 0.035,
                                    color: _kBlue),
                                SizedBox(width: sw * 0.01),
                                Text('Add',
                                    style: TextStyle(
                                        fontSize: sw * 0.028,
                                        fontWeight: FontWeight.w700,
                                        color: _kBlue)),
                              ],
                            ),
                          ),
                        ),
                        children: [
                          ..._modelCtrls.asMap().entries.map((e) {
                            final i   = e.key;
                            final ctrl = e.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: i < _modelCtrls.length - 1
                                      ? sh * 0.012
                                      : 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel(
                                            sw: sw,
                                            label: 'Model ${i + 1}'),
                                        SizedBox(height: sh * 0.006),
                                        _FormField(
                                          sw: sw,
                                          ctrl: ctrl,
                                          hint: 'Enter model name',
                                          icon: Icons
                                              .inventory_2_outlined,
                                          validator: (v) =>
                                          v == null ||
                                              v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_modelCtrls.length > 1) ...[
                                    SizedBox(width: sw * 0.02),
                                    GestureDetector(
                                      onTap: () => _removeModel(i),
                                      child: Container(
                                        width: sw * 0.1,
                                        height: sw * 0.1,
                                        decoration: BoxDecoration(
                                          color: _kRedBg,
                                          borderRadius:
                                          BorderRadius.circular(
                                              sw * 0.025),
                                          border: Border.all(
                                              color: _kRedBorder),
                                        ),
                                        child: Icon(
                                            Icons
                                                .delete_outline_rounded,
                                            size: sw * 0.045,
                                            color: _kRed),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),

                      SizedBox(height: sh * 0.025),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createBrand,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            const Color(0xFFE0E0E0),
                            padding: EdgeInsets.symmetric(
                                vertical: sh * 0.018),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.035),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                              : Text('Create Brand',
                              style: TextStyle(
                                  fontSize: sw * 0.04,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),

                      SizedBox(height: sh * 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final double sw;
  final IconData icon;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.sw,
    required this.icon,
    required this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.075,
                  height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kBorder),
                  ),
                  child:
                  Icon(icon, size: sw * 0.04, color: _kDark),
                ),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final double sw;
  final String label;
  const _FieldLabel({required this.sw, required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
        fontSize: sw * 0.028,
        fontWeight: FontWeight.w700,
        color: _kMuted,
        letterSpacing: 0.5),
  );
}

// ─── Form Field ───────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final double sw;
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.sw,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
          fontSize: sw * 0.036,
          color: _kDark,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: sw * 0.034,
            color: _kMuted,
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: _kMuted, size: sw * 0.045),
        filled: true,
        fillColor: const Color(0xFFF2F4F8),
        contentPadding: EdgeInsets.symmetric(
            horizontal: sw * 0.04,
            vertical: maxLines > 1 ? sw * 0.035 : 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kRed, width: 1.5)),
      ),
    );
  }
}