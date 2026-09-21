import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/group_detail_modal.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

void main() {
  testWidgets('GroupDetailModal renders correctly with i18n and AppTheme', (WidgetTester tester) async {
    final session = FocusSession(
      id: '1',
      startTime: DateTime(2026, 9, 21, 10, 0),
      plannedDuration: const Duration(minutes: 25),
      actualDuration: const Duration(minutes: 25),
      isResting: false,
      isHardcoreMode: true,
      penaltyCount: 0,
      isCompleted: true,
      totalPenaltyTime: const Duration(seconds: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupDetailModal(group: [session]),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify modal is rendered
    expect(find.byType(GroupDetailModal), findsOneWidget);
  });
}
