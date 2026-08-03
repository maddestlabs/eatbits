import 'package:flutter/material.dart';
import '../../theme/eats_theme.dart';
import '../../utils/ir_pack_manager.dart';

class IrPackDialog extends StatefulWidget {
  final VoidCallback onInstalled;

  const IrPackDialog({super.key, required this.onInstalled});

  @override
  State<IrPackDialog> createState() => _IrPackDialogState();
}

class _IrPackDialogState extends State<IrPackDialog> {
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadStatus = {};
  final Map<String, bool> _isDownloading = {};

  Future<void> _startDownload(IrPackInfo pack) async {
    setState(() {
      _isDownloading[pack.id] = true;
      _downloadProgress[pack.id] = 0.05;
      _downloadStatus[pack.id] = 'Starting download...';
    });

    final success = await IrPackManager.instance.downloadAndInstallPack(
      pack,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _downloadProgress[pack.id] = progress;
            _downloadStatus[pack.id] = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading[pack.id] = false;
      });
      if (success) {
        widget.onInstalled();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = IrPackManager.instance.catalog;

    return Dialog(
      backgroundColor: EatsTheme.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: EatsTheme.secondaryMagenta, width: 2),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download, color: EatsTheme.secondaryMagenta, size: 22),
                const SizedBox(width: 10),
                Text(
                  'IMPULSE RESPONSE PACK MANAGER',
                  style: EatsTheme.getPrimaryFontStyle(
                    color: EatsTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: EatsTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Download designated Impulse Response collections to unlock high-definition Convolution Reverb spaces.',
              style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 16),

            ...catalog.map((pack) {
              final isDownloading = _isDownloading[pack.id] ?? false;
              final progress = _downloadProgress[pack.id] ?? 0.0;
              final status = _downloadStatus[pack.id] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EatsTheme.panelHeader,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pack.isDownloaded ? EatsTheme.accentGreen : const Color(0xFF2B3245),
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pack.title.toUpperCase(),
                                style: EatsTheme.getPrimaryFontStyle(
                                  color: EatsTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${pack.description} (${pack.fileSizeMb} MB ZIP)',
                                style: EatsTheme.getPrimaryFontStyle(
                                  color: EatsTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (pack.isDownloaded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: EatsTheme.accentGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: EatsTheme.accentGreen),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: EatsTheme.accentGreen, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'INSTALLED',
                                  style: EatsTheme.getPrimaryFontStyle(
                                    color: EatsTheme.accentGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            icon: isDownloading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.download, size: 14),
                            label: Text(
                              isDownloading ? 'DOWNLOADING...' : 'DOWNLOAD PACK',
                              style: EatsTheme.getPrimaryFontStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EatsTheme.secondaryMagenta,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onPressed: isDownloading ? null : () => _startDownload(pack),
                          ),
                      ],
                    ),
                    if (isDownloading || status.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        backgroundColor: EatsTheme.panelBackground,
                        color: EatsTheme.secondaryMagenta,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: EatsTheme.getPrimaryFontStyle(
                          color: EatsTheme.secondaryMagenta,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'CLOSE',
                  style: EatsTheme.getPrimaryFontStyle(
                    color: EatsTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
