// ------------------------------------------------------------------
// StateNotifier
// ------------------------------------------------------------------
import 'package:hooks_riverpod/all.dart';

extension StateNotifierExt<T> on StateNotifier<T> {
  /// Responsible for notify handlers from errors
  Future<void> doOnError(dynamic error, [StackTrace stackTrace]) async {
    if (onError != null) {
      onError(error, stackTrace);
    }
  }
}
