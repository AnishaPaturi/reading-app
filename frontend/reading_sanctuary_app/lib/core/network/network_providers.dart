import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/reader/presentation/providers/reader_provider.dart';
import 'api_client.dart';
import 'api_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenProvider: () => ref.watch(authTokenProvider),
    onUnauthorized: () {
      // Clear token to return user to login flow without infinite loops
      ref.read(authTokenProvider.notifier).state = null;
    },
    baseUrl: ApiConfig.baseUrl,
  );
});
