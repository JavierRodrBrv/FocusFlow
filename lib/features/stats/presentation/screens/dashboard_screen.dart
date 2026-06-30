import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/background_glows.dart';
import 'package:focus_flow/core/presentation/widgets/premium_loader.dart';

import '../bloc/stats_bloc.dart';
import '../bloc/stats_event.dart';
import '../bloc/stats_state.dart';

import '../widgets/overview_cards.dart';
import '../widgets/week_selector.dart';
import '../widgets/weekly_chart_area.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.statistics,
          style: AppTextStyles.h2,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const BackgroundGlows(),
          SafeArea(
            child: BlocBuilder<StatsBloc, StatsState>(
              builder: (context, state) {
                if (state is StatsLoading || state is StatsInitial) {
                  return const Center(child: PremiumLoader(size: 140.0));
                } else if (state is StatsError) {
                  return Center(
                    child: Text(
                      '${AppLocalizations.of(context)!.errorLoadingStats}\n${state.message}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.error),
                    ),
                  );
                } else if (state is StatsLoaded) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white, // In BlendMode.dstIn, white means keep opaque
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.05, 0.95, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(24.0),
                          sliver: SliverList.list(
                            children: [
                              OverviewCards(state: state),
                              const SizedBox(height: 32),
                              WeekSelector(state: state),
                              const SizedBox(height: 16),
                              WeeklyChartArea(state: state),
                            ],
                          ),
                        ),
                      ],
                    ),
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
}
