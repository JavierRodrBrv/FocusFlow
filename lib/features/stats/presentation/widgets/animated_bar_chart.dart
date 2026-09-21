import 'package:fl_chart/fl_chart.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AnimatedBarChart extends StatelessWidget {
  final Map<int, double> weeklyData;
  final double maxY;
  final void Function(int dayIndex)? onBarTapped;

  const AnimatedBarChart({
    super.key,
    required this.weeklyData,
    required this.maxY,
    this.onBarTapped,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final effectiveMaxY = maxY < 1.0 ? 1.0 : maxY * 1.25;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: effectiveMaxY,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                // Navegar al historial ÚNICAMENTE al soltar un toque rápido (TapUp)
                if (event is FlTapUpEvent) {
                  if (barTouchResponse != null && barTouchResponse.spot != null) {
                    final dayIndex = barTouchResponse.spot!.touchedBarGroupIndex + 1;
                    Future.microtask(() => onBarTapped?.call(dayIndex));
                  }
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.background.withValues(alpha: 0.87),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final totalSecs = (rod.toY * 3600).toInt();
                  int h = totalSecs ~/ 3600;
                  int m = (totalSecs % 3600) ~/ 60;
                  int s = totalSecs % 60;
                  
                  String text = '';
                  if (h > 0) text += '${h}h ';
                  if (m > 0 || h > 0) text += '${m}m ';
                  if (h == 0) text += '${s}s';

                  return BarTooltipItem(
                    text.trim().isEmpty ? '0s' : text.trim(),
                    AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30, // Reservamos espacio para las etiquetas
                  getTitlesWidget: (val, meta) {
                    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                    int index = val.toInt();
                    if (index >= 1 && index <= 7) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          days[index - 1],
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Hide left axis for cleaner premium look
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: effectiveMaxY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              final dayIndex = i + 1;
              final yValue = weeklyData[dayIndex] ?? 0.0;
              
              // Retraso escalonado (staggered delay) para cada barra individual
              final double start = i * 0.04;
              final double end = start + 0.6;
              final double factor = ((value - start) / (end - start)).clamp(0.0, 1.0);
              // Aplicar curva bouncy (easeOutBack) individualizada
              final double curvedFactor = Curves.easeOutBack.transform(factor);

              return BarChartGroupData(
                x: dayIndex,
                barRods: [
                  BarChartRodData(
                    toY: yValue * curvedFactor,
                    width: 22, // Grosor premium de barra
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
