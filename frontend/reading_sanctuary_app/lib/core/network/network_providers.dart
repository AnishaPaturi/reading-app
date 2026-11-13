import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/authentication/data/services/session_storage.dart';
import '../../features/reader/presentation/providers/reader_provider.dart';
import 'api_client.dart';
import 'api_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenProvider: () => ref.read(authTokenProvider),
    onUnauthorized: () {
      // Invalidate memory token on 401 without purging cached user profile
      ref.read(authTokenProvider.notifier).state = null;
    },
    baseUrl: ApiConfig.baseUrl,
  );
});
