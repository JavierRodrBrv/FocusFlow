import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import '../../domain/repositories/feedback_repository.dart';

@LazySingleton(as: IFeedbackRepository)
class FeedbackRepositoryImpl implements IFeedbackRepository {
  final http.Client _client;

  FeedbackRepositoryImpl(this._client);

  @override
  Future<Result<void, Failure>> sendFeedback({
    required String message,
    required String type,
  }) async {
    final subject = '$type [FocusFlow]';
    final url = Uri.parse('https://formsubmit.co/ajax/andaluzcode@gmail.com');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Referer': 'https://focusflow.app',
        },
        body: jsonEncode({
          '_subject': subject,
          'name': 'FocusFlow App User',
          'message': message,
          '_template': 'table',
          '_captcha': 'false',
        }),
      );

      if (response.statusCode == 200) {
        return const Success(null);
      } else {
        return Error(ServerFailure('Server returned ${response.statusCode}'));
      }
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
