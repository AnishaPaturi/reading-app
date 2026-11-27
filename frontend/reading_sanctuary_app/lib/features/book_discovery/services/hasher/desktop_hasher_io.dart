import 'dart:io';
import 'package:crypto/crypto.dart';

Future<String?> computeIoFileSha256(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  } catch (_) {
    return null;
  }
}
