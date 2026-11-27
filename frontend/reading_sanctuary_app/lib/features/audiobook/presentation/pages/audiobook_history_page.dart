import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/audiobook_cover.dart';
import '../../utils/audiobook_duration_utils.dart';

class AudiobookHistoryPage extends ConsumerWidget {
  const AudiobookHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    final historyService = ref.watch(audiobookHistoryServiceProvider);
    final localDb = ref.watch(audiobookLocalDatasourceProvider);
    final sessions = historyService.getAllHistory();

    int totalListeningMs = 0;
    for (final s in sessions) {
      totalListeningMs += s.actualListeningMs;
    }

    final totalListeningHours = (totalListeningMs / (1000 * 60 * 60)).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Listening History',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.ivory : AppColors.textDark,
          ),
        ),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 54, color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No listening sessions recorded yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.ivory : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start listening to any audiobook to track your sessions and listening time automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF2C1810), AppColors.card]
                          : [AppColors.parchment, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.headphones_rounded, color: primary, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalListeningHours Hours',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.ivory : AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Total active listening time across ${sessions.length} sessions',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Recent Sessions',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.ivory : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),

                ...sessions.map((s) {
                  final book = localDb.getAudiobook(s.audiobookId);
                  final duration = Duration(milliseconds: s.actualListeningMs);
                  final timeFormatter = DateFormat.yMMMd().add_jm();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: isDark ? AppColors.card : AppColors.parchment,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: AudiobookCover(
                        coverPath: book?.coverPath,
                        title: book?.title ?? 'Audiobook',
                        author: book?.author,
                        width: 44,
                        height: 44,
                        borderRadius: 6,
                      ),
                      title: Text(
                        book?.title ?? 'Audiobook Session',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${timeFormatter.format(s.startedAt)} · Listened for ${AudiobookDurationUtils.formatDurationHuman(duration)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: primary),
                      onTap: () {
                        if (book != null) {
                          context.push('/audiobooks/${book.id}');
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
