import 'package:flutter/material.dart';
import '../../theme/daw_theme.dart';

/// Shows a small, compact dialog for entering numeric or parameter values manually.
void showCompactValueEditDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  String? minMaxHint,
  required Color accentColor,
  required ValueChanged<String> onSubmit,
  VoidCallback? onResetDefault,
}) {
  final controller = TextEditingController(text: initialValue);

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: DawTheme.panelBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentColor.withOpacity(0.6), width: 1.5),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Title & Optional Reset Default Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DawTheme.getPrimaryFontStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (onResetDefault != null)
                    InkWell(
                      onTap: () {
                        onResetDefault();
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: DawTheme.accentOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (minMaxHint != null && minMaxHint.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  minMaxHint,
                  style: TextStyle(color: DawTheme.textMuted, fontSize: 10),
                ),
              ],
              const SizedBox(height: 10),

              // Compact Numeric Input TextField
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                autofocus: true,
                style: DawTheme.getDisplayFontStyle(
                  color: DawTheme.accentGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: DawTheme.controlBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: accentColor.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                ),
                onSubmitted: (val) {
                  onSubmit(val);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),

              // Action Buttons: Cancel / OK
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('CANCEL', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      onSubmit(controller.text);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
