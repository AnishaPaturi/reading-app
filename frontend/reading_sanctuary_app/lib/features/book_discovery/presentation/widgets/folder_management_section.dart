import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../models/scan_folder.dart';
import '../../services/folder_manager_service.dart';

class FolderManagementSection extends StatelessWidget {
  final FolderManagerService folderManager;
  final VoidCallback onAddFolder;
  final ValueChanged<String> onRemoveFolder;

  const FolderManagementSection({
    super.key,
    required this.folderManager,
    required this.onAddFolder,
    required this.onRemoveFolder,
  });

  @override
  Widget build(BuildContext context) {
    final folders = folderManager.folders;
    final platformDesc = folderManager.scanner.platformCapabilitiesDescription;

    return ClayCard(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_special_rounded, color: ClayColors.deepPurple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Scan Folders (${folders.length})',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onAddFolder,
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Add Folder',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClayColors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Platform capabilities / sandbox limitations banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEADBFA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: ClayColors.deepPurple, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    platformDesc,
                    style: GoogleFonts.inter(fontSize: 11.5, color: ClayColors.textMuted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (folders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.folder_off_outlined, color: ClayColors.softLilac, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No scan folders registered yet.',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a directory (such as Downloads, Books, or Audiobooks) to find books on your device.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 11.5, color: ClayColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: folders.length,
              separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF0EBF9)),
              itemBuilder: (context, index) {
                final folder = folders[index];
                final isRevoked = folder.status == FolderAccessStatus.permissionRevoked;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isRevoked ? const Color(0xFFFDEDEC) : const Color(0xFFF4ECF7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isRevoked ? Icons.folder_off_rounded : Icons.folder_rounded,
                        color: isRevoked ? const Color(0xFFB03A2E) : ClayColors.deepPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRevoked ? const Color(0xFFB03A2E) : const Color(0xFF27AE60),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isRevoked ? 'Permission Revoked' : 'Active & Accessible',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isRevoked ? const Color(0xFFB03A2E) : const Color(0xFF27AE60),
                                ),
                              ),
                              if (folder.lastScannedAt != null) ...[
                                Text(' • ', style: GoogleFonts.inter(fontSize: 11, color: ClayColors.textMuted)),
                                Text(
                                  'Scanned ${folder.discoveredCount} books',
                                  style: GoogleFonts.inter(fontSize: 11, color: ClayColors.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: ClayColors.coral, size: 20),
                      tooltip: 'Remove folder',
                      onPressed: () => onRemoveFolder(folder.id),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
