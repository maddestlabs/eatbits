import 'package:flutter/material.dart';
import '../../models/daw_state.dart';
import '../../models/track_model.dart';
import '../../theme/eats_theme.dart';

Future<void> showRenameTrackDialog(BuildContext context, DawState dawState, TrackChannel track) async {
  final controller = TextEditingController(text: track.name);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: EatsTheme.panelBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: track.color, width: 2),
        ),
        title: Text(
          'RENAME TRACK',
          style: EatsTheme.getPrimaryFontStyle(
            color: EatsTheme.primaryCyan,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter new track name:',
              style: EatsTheme.getPrimaryFontStyle(
                color: EatsTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              style: EatsTheme.getPrimaryFontStyle(
                color: EatsTheme.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: EatsTheme.controlBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: EatsTheme.panelHeader),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: track.color),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (val) {
                final trimmed = val.trim();
                if (trimmed.isNotEmpty) {
                  track.name = trimmed;
                  dawState.notifyState();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(color: EatsTheme.textMuted, fontSize: 12),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: track.color,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                track.name = trimmed;
                dawState.notifyState();
              }
              Navigator.of(context).pop();
            },
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      );
    },
  );
}
