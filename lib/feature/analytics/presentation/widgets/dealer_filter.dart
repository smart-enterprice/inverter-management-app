// Bottom-sheet filter: From / To date pickers + searchable Dealer dropdown.
// Mirrors the date sheet on the Orders page.

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../signup/model/user_model.dart';
import '../../../signup/repository/signup_repository.dart';
import '../../application/date_range_provider.dart';
import '_tokens.dart';

// One-shot 500-row dealer list; cached for the whole session.
final _analyticsDealersProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(signupRepositoryProvider).getDealers(
        page: 1, limit: 500, status: 'active',
      );
});

Future<void> showAnalyticsFilterSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late DateTime _from;
  late DateTime _to;
  String? _dealerId;
  String? _dealerLabel;

  @override
  void initState() {
    super.initState();
    final f = ref.read(analyticsFilterProvider);
    _from = f.from;
    _to = f.to;
    _dealerId = f.dealerId;
    _dealerLabel = f.dealerLabel;
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kP, onPrimary: kSurface,
            surface: kSurface, onSurface: kT1,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: kSurface),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
        if (_from.isAfter(_to)) _from = _to;
      }
    });
  }

  void _apply() {
    final notifier = ref.read(analyticsFilterProvider.notifier);
    notifier.setCustom(_from, _to);
    notifier.setDealer(id: _dealerId, label: _dealerLabel);
    Navigator.pop(context);
  }

  void _clear() {
    ref.read(analyticsFilterProvider.notifier).clearAll();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final dealersAsync = ref.watch(_analyticsDealersProvider);

    String fmtD(DateTime d) => DateFormat('d MMM yyyy').format(d);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          sw * 0.05, sh * 0.02, sw * 0.05,
          sh * 0.04 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: sw * 0.1, height: 3,
            decoration: BoxDecoration(color: kBd,
                borderRadius: BorderRadius.circular(2)),
          )),
          SizedBox(height: sh * 0.022),

          Row(children: [
            Text('Filter', style: TextStyle(
              fontSize: (sw * 0.044).clamp(14.0, 19.0),
              fontWeight: FontWeight.w700, color: kT1)),
            const Spacer(),
            GestureDetector(
              onTap: _clear,
              child: Text('Reset', style: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                color: kRed, fontWeight: FontWeight.w600)),
            ),
          ]),
          SizedBox(height: sh * 0.022),

          // ── From / To ───────────────────────────────────────────────────
          _DateRow(label: 'From', value: fmtD(_from),
              sw: sw, sh: sh, onTap: () => _pickDate(true)),
          SizedBox(height: sh * 0.012),
          _DateRow(label: 'To', value: fmtD(_to),
              sw: sw, sh: sh, onTap: () => _pickDate(false)),
          SizedBox(height: sh * 0.022),

          // ── Dealer dropdown ─────────────────────────────────────────────
          Text('Dealer', style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0),
            color: kT3, fontWeight: FontWeight.w600,
          )),
          SizedBox(height: sh * 0.008),
          _DealerPicker(
            dealersAsync: dealersAsync,
            selectedId: _dealerId,
            onSelected: (u) => setState(() {
              _dealerId = u?.employeeId;
              _dealerLabel = u == null
                  ? null
                  : '${u.employeeName}${u.shopName != null && u.shopName!.isNotEmpty ? " · ${u.shopName}" : ""}';
            }),
          ),

          SizedBox(height: sh * 0.025),
          SizedBox(
            width: double.infinity, height: sh * 0.058,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: kP, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        (sw * 0.03).clamp(8.0, 12.0))),
              ),
              child: Text('Apply', style: TextStyle(
                fontSize: (sw * 0.038).clamp(13.0, 16.0),
                fontWeight: FontWeight.w700, color: kSurface)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label, required this.value,
    required this.sw, required this.sh, required this.onTap,
  });
  final String label, value;
  final double sw, sh;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sh * 0.014),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
        border: Border.all(color: kBd, width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.calendar_month_outlined,
            size: (sw * 0.04).clamp(14.0, 18.0), color: kP),
        SizedBox(width: sw * 0.025),
        Text(label, style: TextStyle(
            fontSize: (sw * 0.032).clamp(11.0, 14.0),
            color: kT3, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: TextStyle(
            fontSize: (sw * 0.034).clamp(11.5, 15.0),
            color: kT1, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _DealerPicker extends StatelessWidget {
  const _DealerPicker({
    required this.dealersAsync,
    required this.selectedId,
    required this.onSelected,
  });
  final AsyncValue<List<UserModel>> dealersAsync;
  final String? selectedId;
  final void Function(UserModel?) onSelected;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final dealers = dealersAsync.value ?? const <UserModel>[];

    UserModel? selected;
    if (selectedId != null) {
      for (final d in dealers) {
        if (d.employeeId == selectedId) { selected = d; break; }
      }
    }

    return DropdownSearch<UserModel?>(
      items: [null, ...dealers],
      selectedItem: selected,
      onChanged: onSelected,
      itemAsString: (u) => u == null
          ? 'All dealers'
          : '${u.employeeName}'
            '${u.shopName != null && u.shopName!.isNotEmpty ? " · ${u.shopName}" : ""}',
      compareFn: (a, b) => a?.employeeId == b?.employeeId,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search dealers…',
            prefixIcon: const Icon(Icons.search_rounded, color: kT4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kBd, width: 0.5),
            ),
          ),
        ),
        constraints: BoxConstraints(maxHeight: sw * 1.2),
        emptyBuilder: (_, __) => dealersAsync.isLoading
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: kP, strokeWidth: 2),
              ))
            : const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No dealers',
                    style: TextStyle(color: kT4)),
              )),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.025),
          filled: true, fillColor: kBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.028).clamp(8.0, 12.0)),
              borderSide: const BorderSide(color: kBd, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.028).clamp(8.0, 12.0)),
              borderSide: const BorderSide(color: kBd, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.028).clamp(8.0, 12.0)),
              borderSide: const BorderSide(color: kP, width: 1.5)),
        ),
      ),
    );
  }
}
