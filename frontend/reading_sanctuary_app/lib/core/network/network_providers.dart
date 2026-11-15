import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reader/presentation/providers/reader_provider.dart';
import 'api_client.dart';
import 'api_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  // Capture the stable StateController, not the changing token value.
  final tokenController = ref.read(authTokenProvider.notifier);

  return ApiClient(
    tokenProvider: () => tokenController.state,

    onUnauthorized: () {
      // Clear the current token when the backend rejects it.
      tokenController.state = null;
    },

    baseUrl: ApiConfig.baseUrl,
  );
});
