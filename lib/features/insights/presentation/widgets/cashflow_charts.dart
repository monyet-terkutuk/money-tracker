import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icon_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../home/domain/monthly_insight.dart';
import '../../domain/cashflow_chart_provider.dart';

class SixMonthCashflowCard extends StatelessWidget {
  final List<MonthlyCashflowPoint> points;

  const SixMonthCashflowCard({super.key, required this.points});

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);
    final incomeColor = AppPalette.incomeColor(context);
    final expenseColor = AppPalette.accent(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arus Kas 6 Bulan',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: incomeColor, label: 'Masuk'),
                  const SizedBox(width: 12),
                  _LegendDot(color: expenseColor, label: 'Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _CashflowBarPainter(
                points: points,
                incomeColor: incomeColor,
                expenseColor: expenseColor,
                gridColor: AppPalette.borderColor(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: points.map((p) {
              return Expanded(
                child: Text(
                  _shortMonths[p.month.month - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CashflowBarPainter extends CustomPainter {
  final List<MonthlyCashflowPoint> points;
  final Color incomeColor;
  final Color expenseColor;
  final Color gridColor;

  _CashflowBarPainter({
    required this.points,
    required this.incomeColor,
    required this.expenseColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = points.fold<int>(
      0,
      (prev, p) => math.max(prev, math.max(p.income, p.expense)),
    );

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;

    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = size.height * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (maxVal <= 0 || points.isEmpty) return;

    final groupWidth = size.width / points.length;
    final barWidth = math.min(12.0, groupWidth * 0.24);
    final gap = 4.0;

    final incomePaint = Paint()..color = incomeColor;
    final expensePaint = Paint()..color = expenseColor;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final centerX = groupWidth * i + groupWidth / 2;

      final incomeH = (p.income / maxVal) * (size.height - 6);
      final expenseH = (p.expense / maxVal) * (size.height - 6);

      if (incomeH > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            centerX - barWidth - gap / 2,
            size.height - incomeH,
            barWidth,
            incomeH,
          ),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        );
        canvas.drawRRect(rect, incomePaint);
      }

      if (expenseH > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            centerX + gap / 2,
            size.height - expenseH,
            barWidth,
            expenseH,
          ),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        );
        canvas.drawRRect(rect, expensePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CashflowBarPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.incomeColor != incomeColor ||
      oldDelegate.expenseColor != expenseColor;
}

class ExpenseDonutCard extends StatelessWidget {
  final List<CategorySpending> categoriesSpend;
  final List<Category> categories;
  final int totalExpense;

  const ExpenseDonutCard({
    super.key,
    required this.categoriesSpend,
    required this.categories,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (totalExpense <= 0 || categoriesSpend.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final secondaryText = AppPalette.secondaryTextColor(context);
    final topItems = categoriesSpend.take(5).toList();
    final segments = topItems.map((item) {
      final cat = categories.where((c) => c.id == item.categoryId).firstOrNull;
      final color = resolveCategoryAccent(
        cat?.icon,
        fallback: AppPalette.accent(context),
      );
      return _DonutSegment(
        label: item.categoryName.isNotEmpty
            ? item.categoryName
            : (cat?.name ?? 'Lainnya'),
        amount: item.amount,
        share: totalExpense > 0 ? item.amount / totalExpense : 0.0,
        color: color,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komposisi Pengeluaran',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(112, 112),
                      painter: _DonutChartPainter(
                        segments: segments,
                        trackColor: AppPalette.borderColor(context),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCompactCurrency(totalExpense),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: segments.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(s.share * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: secondaryText,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  final String label;
  final int amount;
  final double share;
  final Color color;

  const _DonutSegment({
    required this.label,
    required this.amount,
    required this.share,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final Color trackColor;

  _DonutChartPainter({required this.segments, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    double startAngle = -math.pi / 2;
    for (final s in segments) {
      final sweepAngle = (s.share * 2 * math.pi).clamp(0.0, 2 * math.pi);
      if (sweepAngle <= 0.02) continue;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.03, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppPalette.secondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}
