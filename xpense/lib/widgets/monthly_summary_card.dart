import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/constants.dart';

class MonthlySummaryCard extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalSpent;
  final double? totalBudget;

  const MonthlySummaryCard({
    super.key,
    required this.categoryTotals,
    required this.totalSpent,
    this.totalBudget,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: Constants.currencySymbol);

    double percent = 0.0;
    bool isOverBudget = false;
    if (totalBudget != null && totalBudget! > 0) {
      percent = (totalSpent / totalBudget!).clamp(0.0, 1.0);
      isOverBudget = totalSpent > totalBudget!;
    }

    final progressColor = isOverBudget
        ? AppColors.error
        : percent > 0.75
            ? const Color(0xFFE65100) // deep orange warning
            : const Color(0xFFFFA726); // amber good

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5D4037), // Brown 700
            Color(0xFF6D4C41), // Brown 600
            Color(0xFF8D6E63), // Brown 400
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent This Month',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(totalSpent),
                      style: AppTypography.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Always-visible Budget Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalBudget != null && totalBudget! > 0
                      ? 'Budget Used'
                      : 'No Budget Set',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                if (totalBudget != null && totalBudget! > 0)
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%  of  ${currencyFormat.format(totalBudget)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percent),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: totalBudget != null && totalBudget! > 0 ? value : 0,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      totalBudget != null && totalBudget! > 0
                          ? progressColor
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    minHeight: 12,
                  );
                },
              ),
            ),
            if (isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Over budget by ${currencyFormat.format(totalSpent - totalBudget!)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.orange.shade200,
                      ),
                    ),
                  ],
                ),
              ),

            if (categoryTotals.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 16),
              Text(
                'Spending Breakdown',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildTopCategories(categoryTotals, currencyFormat),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTopCategories(
      Map<String, double> totals, NumberFormat currencyFormat) {
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(6).toList();

    return topEntries.map((entry) {
      final percentage = totalSpent > 0 ? (entry.value / totalSpent) : 0.0;
      final categoryColor = AppColors.getCategoryColor(entry.key);

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
                Text(
                  currencyFormat.format(entry.value),
                  style: AppTypography.labelMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
