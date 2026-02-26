import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/presentation/bloc/session_history_bloc.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_detail_modal.dart';

class SessionHistoryPage extends StatelessWidget {
  const SessionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<SessionHistoryBloc>()..add(LoadSessionHistory()),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Historial de Sesiones',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<SessionHistoryBloc, SessionHistoryState>(
          builder: (context, state) {
            if (state.status == SessionHistoryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == SessionHistoryStatus.error) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Error desconocido',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (state.sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay sesiones registradas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              itemCount: state.sessions.length,
              itemBuilder: (context, index) {
                final session = state.sessions[index];
                return Dismissible(
                  key: Key(session.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent.withOpacity(0.2),
                    child: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                  onDismissed: (direction) {
                    context.read<SessionHistoryBloc>().add(
                      DeleteSession(session.id),
                    );
                  },
                  child: SessionCard(
                    session: session,
                    onTap: () => _showSessionDetails(context, session),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, FocusSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionDetailModal(session: session),
    );
  }
}
