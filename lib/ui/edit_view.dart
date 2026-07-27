import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import 'piano_roll_view.dart';
import 'tracker_view.dart';

class EditView extends StatelessWidget {
  final DawState dawState;

  const EditView({super.key, required this.dawState});

  @override
  Widget build(BuildContext context) {
    final track = dawState.activeTrack;

    return Column(
      children: [
        // Editor Header View Switcher
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: DawTheme.panelHeader,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: track.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'EDITING: ${track.name.toUpperCase()}',
                style: DawTheme.getPrimaryFontStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              Text('MODE: ', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textMuted, fontSize: 10)),
              ChoiceChip(
                label: Text('PIANO ROLL', style: DawTheme.getPrimaryFontStyle(fontSize: 10)),
                selected: track.activeView == MusicViewType.pianoRoll,
                selectedColor: DawTheme.primaryCyan,
                onSelected: (_) {
                  dawState.setTrackActiveView(track, MusicViewType.pianoRoll);
                },
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text('TRACKER', style: DawTheme.getPrimaryFontStyle(fontSize: 10)),
                selected: track.activeView == MusicViewType.tracker,
                selectedColor: DawTheme.secondaryMagenta,
                onSelected: (_) {
                  dawState.setTrackActiveView(track, MusicViewType.tracker);
                },
              ),

            ],
          ),
        ),

        // Main Editor Canvas
        Expanded(
          child: track.activeView == MusicViewType.tracker
              ? TrackerView(dawState: dawState)
              : PianoRollView(dawState: dawState),
        ),
      ],
    );
  }
}
