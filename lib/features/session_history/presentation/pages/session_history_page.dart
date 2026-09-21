import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/session_history/presentation/bloc/session_history_bloc.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/history_filter_bar.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_history_list_content.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';

class SessionHistoryPage extends StatelessWidget {
  final DateTime? filterDate;

  const SessionHistoryPage({super.key, this.filterDate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<SessionHistoryBloc>();
        if (filterDate != null) {
          bloc.add(SetFilterDate(filterDate));
        } else {
          bloc.add(LoadSessionHistory());
        }
        return bloc;
      },
      child: const _SessionHistoryView(),
    );
  }
}

class _SessionHistoryView extends StatelessWidget {
  const _SessionHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.historyTitle,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<SessionHistoryBloc, SessionHistoryState>(
        builder: (context, state) {
          return Column(
            children: [
              if (state.filterDate != null)
                HistoryFilterBar(filterDate: state.filterDate!),

              Expanded(
                child: SessionHistoryListContent(state: state),
              ),
            ],
          );
        },
      ),
    );
  }
}
