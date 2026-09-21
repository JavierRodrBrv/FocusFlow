import 'package:flutter/material.dart';
import 'package:focus_flow/core/presentation/widgets/premium_loader.dart';
import 'package:focus_flow/features/session_history/domain/entities/history_list_item.dart';
import 'package:focus_flow/features/session_history/presentation/bloc/session_history_bloc.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/history_date_header.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/history_empty_state.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/history_list_items_builder.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';

class SessionHistoryListContent extends StatelessWidget {
  final SessionHistoryState state;

  const SessionHistoryListContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == SessionHistoryStatus.loading) {
      return const Center(child: PremiumLoader(size: 140.0));
    }

    if (state.status == SessionHistoryStatus.error) {
      return Center(
        child: Text(
          state.errorMessage ?? AppLocalizations.of(context)!.unknownError,
          style: AppTextStyles.body.copyWith(color: AppColors.error),
        ),
      );
    }

    if (state.items.isEmpty) {
      return HistoryEmptyState(filterDate: state.filterDate);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 32, top: 8, left: 16, right: 16),
          sliver: SliverList.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];

              if (item is HistoryDateHeader) {
                return HistoryDateHeaderWidget(date: item.date);
              } else if (item is HistorySingleSession) {
                return HistoryListItemsBuilder.buildSingleSession(context, item);
              } else if (item is HistoryGroupedSession) {
                return HistoryListItemsBuilder.buildGroupedSession(context, item);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
