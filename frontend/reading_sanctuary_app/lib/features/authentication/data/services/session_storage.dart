import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_storage_interface.dart';
import 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart'
    if (dart.library.io) 'session_storage_io.dart' as impl;

export 'session_storage_interface.dart';

AuthSessionStorage getAuthSessionStorage() => impl.createPlatformSessionStorage();

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return getAuthSessionStorage();
});
