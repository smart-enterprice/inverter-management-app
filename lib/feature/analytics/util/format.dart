// Indian-style currency and number formatting + safe local-date helpers.
// Centralised so charts/cards format consistently and no caller is tempted
// to use `DateTime.toIso8601String()` (which silently emits UTC and breaks
// "today" boundaries in IST).

import 'package:intl/intl.dart';

/// "YYYY-MM-DD" built from LOCAL year/month/day. Never UTC.
String localYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Date of the 1st of [d]'s month (local).
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// Date of the last day of [d]'s month (local).
DateTime monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);

/// Same span as [from..to], shifted backward by its length.
({DateTime from, DateTime to}) previousPeriod(DateTime from, DateTime to) {
  final span = to.difference(from).inDays + 1;
  final prevTo = from.subtract(const Duration(days: 1));
  final prevFrom = prevTo.subtract(Duration(days: span - 1));
  return (from: prevFrom, to: prevTo);
}

final _fmtFull = NumberFormat('#,##,##0', 'en_IN');
final _fmt1dp = NumberFormat('#,##,##0.0', 'en_IN');

/// Compact INR: ₹1.2Cr / ₹4.5L / ₹12.5K / ₹540.
String formatINR(num? n) {
  if (n == null) return '₹0';
  final v = n.abs();
  final sign = n < 0 ? '-' : '';
  if (v >= 10000000) return '$sign₹${_fmt1dp.format(v / 10000000)}Cr';
  if (v >= 100000)   return '$sign₹${_fmt1dp.format(v / 100000)}L';
  if (v >= 1000)     return '$sign₹${_fmt1dp.format(v / 1000)}K';
  return '$sign₹${_fmtFull.format(v)}';
}

/// Full ₹ with Indian grouping. Used in tooltips where the compact form
/// would be ambiguous.
String formatINRFull(num? n) {
  if (n == null) return '₹0';
  return '₹${_fmtFull.format(n)}';
}

/// Plain count with Indian grouping. e.g. 12,345.
String formatCount(num? n) => _fmtFull.format(n ?? 0);

/// Returns ("+12%", isUp) or ("—", false) when previous is zero / null.
({String text, bool isUp, bool meaningful}) deltaPct(num? current, num? previous) {
  final c = (current ?? 0).toDouble();
  final p = (previous ?? 0).toDouble();
  if (p == 0) {
    if (c == 0) return (text: '—', isUp: false, meaningful: false);
    return (text: 'new', isUp: true, meaningful: true);
  }
  final pct = ((c - p) / p) * 100.0;
  final sign = pct >= 0 ? '+' : '';
  final txt = '$sign${pct.toStringAsFixed(pct.abs() >= 100 ? 0 : 1)}%';
  return (text: txt, isUp: pct >= 0, meaningful: true);
}
