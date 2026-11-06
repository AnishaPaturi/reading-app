import 'package:intl/intl.dart';

String timeAgo(DateTime? t) {
  if (t == null) return 'Not opened yet';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return DateFormat.yMMMd().format(t);
}
