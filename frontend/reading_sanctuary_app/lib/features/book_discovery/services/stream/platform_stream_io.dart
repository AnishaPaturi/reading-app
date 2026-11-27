import 'dart:io';

Stream<List<int>> openDesktopFileStream(String path) {
  return File(path).openRead();
}
