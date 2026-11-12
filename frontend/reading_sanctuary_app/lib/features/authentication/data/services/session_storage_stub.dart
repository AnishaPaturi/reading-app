import 'session_storage_interface.dart';

AuthSessionStorage createPlatformSessionStorage() =>
    throw UnsupportedError('Cannot create auth session storage without platform implementation');
