import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/web_book_scanner.dart';

void main() {
  late WebBookScanner scanner;

  setUp(() {
    scanner = WebBookScanner();
  });

  test('platformCapabilitiesDescription clearly explains browser sandbox constraints', () {
    expect(scanner.platformCapabilitiesDescription, contains('sandbox'));
    expect(scanner.platformCapabilitiesDescription, contains('Downloads'));
  });

  test('scanFolder returns in-memory discovered files matching extensions', () async {
    const folder = ScanFolder(
      id: 'web-1',
      name: 'Web Session',
      pathOrUri: 'web_session://123',
    );

    // Initial empty scan
    final initial = await scanner.scanFolder(folder);
    expect(initial, isEmpty);
    expect(await scanner.verifyPermission(folder), isFalse);
  });
}
