import 'dart:async';
import 'dart:js_interop';
import 'audiobook_storage_interface.dart';

@JS('window.indexedDB')
external _IDBFactory? get _indexedDB;

extension type _IDBFactory._(JSObject _) implements JSObject {
  external _IDBOpenDBRequest open(String name, int version);
}

extension type _IDBStringList._(JSObject _) implements JSObject {
  external bool contains(String value);
}

extension type _IDBDatabase._(JSObject _) implements JSObject {
  external _IDBStringList get objectStoreNames;
  external _IDBObjectStore createObjectStore(String name);
  external _IDBTransaction transaction(String storeName, String mode);
}

extension type _IDBTransaction._(JSObject _) implements JSObject {
  external _IDBObjectStore objectStore(String name);
  external set oncomplete(JSFunction? handler);
  external set onerror(JSFunction? handler);
  external set onabort(JSFunction? handler);
  external JSAny? get error;
}

extension type _IDBObjectStore._(JSObject _) implements JSObject {
  @JS('get')
  external _IDBRequest getItem(JSAny key);
  @JS('put')
  external _IDBRequest putItem(JSAny value, JSAny key);
}

extension type _IDBRequest._(JSObject _) implements JSObject {
  external JSAny? get result;
  external JSAny? get error;
  external set onsuccess(JSFunction? handler);
  external set onerror(JSFunction? handler);
}

extension type _IDBOpenDBRequest._(JSObject _) implements _IDBRequest {
  external set onupgradeneeded(JSFunction? handler);
  external set onblocked(JSFunction? handler);
}

class IndexedDbAudiobookStorageBackend implements AudiobookStorageBackend {
  static const String _dbName = 'reading_sanctuary_audiobooks';
  static const int _dbVersion = 1;
  static const String _storeName = 'stores';

  _IDBDatabase? _db;
  Future<void>? _opening;

  @override
  Future<void> init() async {
    if (_db != null) return;
    if (_opening != null) {
      await _opening;
      return;
    }

    final future = _openDb();
    _opening = future;
    try {
      await future;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> _openDb() async {
    final factory = _indexedDB;
    if (factory == null) {
      throw const AudiobookStorageException(
        'IndexedDB is not available in this browser environment.',
      );
    }

    final completer = Completer<void>();
    late final _IDBOpenDBRequest request;

    try {
      request = factory.open(_dbName, _dbVersion);
    } catch (e) {
      throw AudiobookStorageException('Failed to open IndexedDB "$_dbName"', e);
    }

    request.onupgradeneeded = ((JSAny? _) {
      try {
        final db = request.result as _IDBDatabase?;
        if (db != null && !db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(
            AudiobookStorageException('Failed to upgrade IndexedDB schema', e),
          );
        }
      }
    }).toJS;

    request.onsuccess = ((JSAny? _) {
      final db = request.result as _IDBDatabase?;
      if (db == null) {
        if (!completer.isCompleted) {
          completer.completeError(
            const AudiobookStorageException('IndexedDB opened without a database handle.'),
          );
        }
        return;
      }
      _db = db;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS;

    request.onerror = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          AudiobookStorageException(
            'IndexedDB open error',
            request.error?.dartify(),
          ),
        );
      }
    }).toJS;

    request.onblocked = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const AudiobookStorageException(
            'IndexedDB open request was blocked by another connection.',
          ),
        );
      }
    }).toJS;

    return completer.future;
  }

  @override
  Future<String?> readStore(String key) async {
    await init();
    final db = _db;
    if (db == null) {
      throw const AudiobookStorageException('IndexedDB database handle is unavailable.');
    }

    final completer = Completer<String?>();
    final tx = db.transaction(_storeName, 'readonly');
    final store = tx.objectStore(_storeName);
    final req = store.getItem(key.toJS);

    req.onsuccess = ((JSAny? _) {
      if (completer.isCompleted) return;
      final res = req.result;
      if (res == null) {
        completer.complete(null);
      } else {
        final dartVal = res.dartify();
        completer.complete(dartVal?.toString());
      }
    }).toJS;

    req.onerror = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          AudiobookStorageException('IndexedDB read error for "$key"', req.error?.dartify()),
        );
      }
    }).toJS;

    tx.onabort = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          AudiobookStorageException('IndexedDB read transaction aborted for "$key"', tx.error?.dartify()),
        );
      }
    }).toJS;

    return completer.future;
  }

  @override
  Future<void> writeStore(String key, String value) async {
    await init();
    final db = _db;
    if (db == null) {
      throw const AudiobookStorageException('IndexedDB database handle is unavailable.');
    }

    final completer = Completer<void>();
    final tx = db.transaction(_storeName, 'readwrite');
    final store = tx.objectStore(_storeName);
    final req = store.putItem(value.toJS, key.toJS);

    tx.oncomplete = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS;

    req.onerror = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          AudiobookStorageException('IndexedDB write request error for "$key"', req.error?.dartify()),
        );
      }
    }).toJS;

    tx.onerror = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          AudiobookStorageException('IndexedDB write transaction error for "$key"', tx.error?.dartify()),
        );
      }
    }).toJS;

    tx.onabort = ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          AudiobookStorageException('IndexedDB write transaction aborted for "$key"', tx.error?.dartify()),
        );
      }
    }).toJS;

    return completer.future;
  }
}

AudiobookStorageBackend createPlatformAudiobookStorage({String? customDirectoryPath}) {
  return IndexedDbAudiobookStorageBackend();
}
