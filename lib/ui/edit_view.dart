import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import 'piano_roll_view.dart';
import 'tracker_view.dart';
import 'script_view.dart';
import 'widgets/skeuomorphic_hardware_button.dart';

class EditView extends StatelessWidget {
  final DawState dawState;

  const EditView({super.key, required this.dawState});

  @override
  Widget build(BuildContext context) {
    final track = dawState.activeTrack;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Editor Header View Switcher
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: DawTheme.panelHeader,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: track.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isMobile ? track.name.toUpperCase() : 'EDITING: ${track.name.toUpperCase()}',
                  style: DawTheme.getPrimaryFontStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (track.activeView == MusicViewType.pianoRoll) ...[
                if (!isMobile) Text('SNAP: ', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
                DropdownButton<double>(
                  value: dawState.quantizeSnap,
                  dropdownColor: DawTheme.panelBackground,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('1/32', style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(value: 1.0, child: Text('1/16', style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(value: 2.0, child: Text('1/8', style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(value: 4.0, child: Text('1/4', style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(value: 0.0, child: Text('No Snap', style: TextStyle(fontSize: 11))),
                  ],
                  onChanged: (val) {
                    if (val != null) dawState.setQuantizeSnap(val);
                  },
                ),
                const SizedBox(width: 8),
              ] else if (track.activeView == MusicViewType.tracker) ...[
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: DawTheme.textSecondary, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove Tracker Column',
                  onPressed: () => dawState.setTrackerColumns(track, track.trackerColumns - 1),
                ),
                const SizedBox(width: 4),
                Text(
                  'COLS: ${track.trackerColumns}',
                  style: DawTheme.getDisplayFontStyle(color: DawTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 11),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: DawTheme.primaryCyan, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add Tracker Column',
                  onPressed: () => dawState.setTrackerColumns(track, track.trackerColumns + 1),
                ),
                const SizedBox(width: 8),
              ],

              // View Switcher Buttons (Icon-only on Mobile)
              SkeuomorphicHardwareButton(
                label: isMobile ? null : 'PIANO ROLL',
                icon: Icons.piano,
                isActive: track.activeView == MusicViewType.pianoRoll,
                activeColor: DawTheme.primaryCyan,
                onTap: () => dawState.setTrackActiveView(track, MusicViewType.pianoRoll),
                height: 32,
              ),
              const SizedBox(width: 6),
              SkeuomorphicHardwareButton(
                label: isMobile ? null : 'TRACKER',
                icon: Icons.view_column,
                isActive: track.activeView == MusicViewType.tracker,
                activeColor: DawTheme.secondaryMagenta,
                onTap: () => dawState.setTrackActiveView(track, MusicViewType.tracker),
                height: 32,
              ),
              const SizedBox(width: 6),
              SkeuomorphicHardwareButton(
                label: isMobile ? null : 'SCRIPT',
                icon: Icons.code,
                isActive: track.activeView == MusicViewType.script,
                activeColor: DawTheme.accentGold,
                onTap: () => dawState.setTrackActiveView(track, MusicViewType.script),
                height: 32,
              ),
            ],
          ),
        ),

        // Main Editor Canvas
        Expanded(
          child: _buildActiveView(track.activeView),
        ),
      ],
    );
  }

  Widget _buildActiveView(MusicViewType activeView) {
    switch (activeView) {
      case MusicViewType.tracker:
        return TrackerView(dawState: dawState);
      case MusicViewType.script:
        return ScriptView(dawState: dawState);
      case MusicViewType.pianoRoll:
      default:
        return PianoRollView(dawState: dawState);
    }
  }
}
