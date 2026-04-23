import 'package:flutter/material.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/product_model.dart';
import '../../../widgets/circle_button.dart';

class ProductPriceHistory extends StatelessWidget {
  final List<PriceHistory> history; // ✅ List not single

  const ProductPriceHistory({super.key, required this.history});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppBar ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04,
                vertical: sh * 0.02,
              ),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  SizedBox(width: sw * 0.04),
                  Text(
                    'Price History',
                    style: TextStyle(
                      fontSize: sw * 0.048,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: history.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history,
                        size: sw * 0.15, color: Colors.grey[300]),
                    SizedBox(height: sh * 0.02),
                    Text(
                      'No price history available',
                      style: TextStyle(
                        fontSize: sw * 0.038,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final h = history[index];
                  final oldPrice =
                      h.oldPrice?.toStringAsFixed(0) ?? 'N/A';
                  final newPrice =
                      h.newPrice?.toStringAsFixed(0) ?? 'N/A';
                  final date = _formatDate(h.changedAt);
                  final isPriceUp =
                      (h.newPrice ?? 0) > (h.oldPrice ?? 0);

                  return Container(
                    margin: EdgeInsets.only(bottom: sw * 0.03),
                    padding: EdgeInsets.all(sw * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sw * 0.03),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Date + badge ──
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: sw * 0.035,
                                color: Colors.grey[500]),
                            SizedBox(width: sw * 0.015),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: sw * 0.032,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: sw * 0.025,
                                  vertical: sw * 0.01),
                              decoration: BoxDecoration(
                                color: isPriceUp
                                    ? Colors.red[50]
                                    : Colors.green[50],
                                borderRadius:
                                BorderRadius.circular(sw * 0.05),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPriceUp
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: sw * 0.035,
                                    color: isPriceUp
                                        ? Colors.red[600]
                                        : Colors.green[600],
                                  ),
                                  SizedBox(width: sw * 0.01),
                                  Text(
                                    isPriceUp
                                        ? 'Increased'
                                        : 'Decreased',
                                    style: TextStyle(
                                      fontSize: sw * 0.028,
                                      fontWeight: FontWeight.w600,
                                      color: isPriceUp
                                          ? Colors.red[600]
                                          : Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: sw * 0.03),

                        // ── Price row ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Old Price',
                                  style: TextStyle(
                                    fontSize: sw * 0.028,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: sw * 0.01),
                                Text(
                                  '₹$oldPrice',
                                  style: TextStyle(
                                    fontSize: sw * 0.042,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                    decoration:
                                    TextDecoration.lineThrough,
                                    decorationColor: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: sw * 0.05),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: isPriceUp
                                    ? Colors.red[400]
                                    : Colors.green[400],
                                size: sw * 0.06,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'New Price',
                                  style: TextStyle(
                                    fontSize: sw * 0.028,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: sw * 0.01),
                                Text(
                                  '₹$newPrice',
                                  style: TextStyle(
                                    fontSize: sw * 0.042,
                                    fontWeight: FontWeight.bold,
                                    color: isPriceUp
                                        ? Colors.red[600]
                                        : Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // ── Note ──
                        if (h.changeReason != null &&
                            h.changeReason!.trim().isNotEmpty) ...[
                          SizedBox(height: sw * 0.025),
                          Divider(color: Colors.grey[200], height: 1),
                          SizedBox(height: sw * 0.02),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_outlined,
                                  size: sw * 0.038,
                                  color: Colors.grey[500]),
                              SizedBox(width: sw * 0.02),
                              Expanded(
                                child: Text(
                                  h.changeReason!,
                                  style: TextStyle(
                                    fontSize: sw * 0.032,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}