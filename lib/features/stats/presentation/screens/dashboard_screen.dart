import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/stats_bloc.dart';
import '../bloc/stats_event.dart';
import '../bloc/stats_state.dart';
import '../widgets/animated_bar_chart.dart';
import '../../../session_history/presentation/pages/session_history_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<StatsBloc>()..add(LoadDailyStats()),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.2),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: BlocBuilder<StatsBloc, StatsState>(
              builder: (context, state) {
                if (state is StatsLoading || state is StatsInitial) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                } else if (state is StatsError) {
                  return Center(
                    child: Text(
                      'Error cargando estadísticas:\n${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                } else if (state is StatsLoaded) {
                  return ListView(
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      // Overview Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassCard(
                              child: _buildStatItem(
                                title: 'Racha Actual',
                                value: '${state.currentStreak} Días',
                                icon: Icons.local_fire_department_rounded,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGlassCard(
                              child: _buildStatItem(
                                title: 'Total Enfocado',
                                value: _formatDuration(state.totalSecondsFocus),
                                icon: Icons.timer_rounded,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Weekly Chart
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (state.hasPreviousWeek)
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: () {
                                context.read<StatsBloc>().add(LoadDailyStats(
                                  baseDate: state.currentWeekStart.subtract(const Duration(days: 7)),
                                ));
                              },
                            )
                          else
                            const SizedBox(width: 48),

                          Text(
                            !state.hasNextWeek 
                                ? 'Esta Semana'
                                : 'Sem ${state.currentWeekStart.day}/${state.currentWeekStart.month} - ${state.currentWeekStart.add(const Duration(days: 6)).day}/${state.currentWeekStart.add(const Duration(days: 6)).month}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          if (state.hasNextWeek)
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: () {
                                context.read<StatsBloc>().add(LoadDailyStats(
                                  baseDate: state.currentWeekStart.add(const Duration(days: 7)),
                                ));
                              },
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: _buildGlassCard(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          child: AnimatedBarChart(
                            weeklyData: state.weeklyBarData,
                            maxY: state.weeklyBarData.values.fold(0.0, (m, v) => v > m ? v : m),
                            onBarTapped: (dayIndex) {
                              // dayIndex es 1..7 (Lunes..Domingo)
                              final targetDate = state.currentWeekStart.add(Duration(days: dayIndex - 1));
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionHistoryPage(filterDate: targetDate),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds == 0) return '0s';
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    
    List<String> parts = [];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (s > 0) parts.add('${s}s');
    
    return parts.join(' ');
  }
}
