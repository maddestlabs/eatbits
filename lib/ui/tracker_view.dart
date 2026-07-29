import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import 'widgets/eatbits_slider.dart';

class TrackerView extends StatefulWidget {
  final DawState dawState;

  const TrackerView({super.key, required this.dawState});

  @override
  State<TrackerView> createState() => _TrackerViewState();
}

class _TrackerViewState extends State<TrackerView> {
  final ScrollController _verticalScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final track = widget.dawState.activeTrack;
    final totalSteps = widget.dawState.activePattern.lengthSteps;
    final totalColumns = track.trackerColumns;

    final noteMap = <String, Note>{};
    for (final n in track.notes) {
      noteMap['${n.startStep.toInt()}_${n.column}'] = n;
    }

    return Column(
      children: [
        // Sub-channel Column Titles Header
        Container(
          color: DawTheme.controlBackground,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  'ROW',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DawTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(totalColumns, (colIdx) {
                      return SizedBox(
                        width: 130,
                        child: Text(
                          'COL 0${colIdx + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colIdx % 2 == 0 ? DawTheme.primaryCyan : DawTheme.secondaryMagenta,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Vertical Tracker Step Matrix
        Expanded(
          child: ListView.builder(
            controller: _verticalScroll,
            itemCount: totalSteps,
            itemBuilder: (context, stepIdx) {
              final isCurrentStep = widget.dawState.isPlaying && widget.dawState.currentStep == stepIdx;
              final isBeatFour = stepIdx % 4 == 0;

              return Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrentStep
                      ? DawTheme.primaryCyan.withOpacity(0.25)
                      : (isBeatFour ? DawTheme.panelBackground : DawTheme.backgroundDark),
                  border: Border(
                    bottom: BorderSide(
                      color: isBeatFour ? DawTheme.panelHeader : DawTheme.controlBackground.withOpacity(0.4),
                      width: isBeatFour ? 1.5 : 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Step Row Counter
                    SizedBox(
                      width: 44,
                      child: Center(
                        child: Text(
                          stepIdx.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: isCurrentStep
                                ? DawTheme.accentGreen
                                : (isBeatFour ? DawTheme.accentGold : DawTheme.textMuted),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),

                    // Sub-Channel Note Data Columns
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(totalColumns, (colIdx) {
                            // Find note event matching startStep & column index via O(1) map
                            final noteMatch = noteMap['${stepIdx}_$colIdx'] ?? Note(id: '', pitch: -1, startStep: -1);

                            final hasNote = noteMatch.pitch != -1;
                            final noteStr = hasNote ? _formatTrackerNote(noteMatch.pitch) : '---';
                            final volStr = hasNote ? 'V${(noteMatch.velocity * 99).toInt().toString().padLeft(2, '0')}' : '..';
                            final fxStr = hasNote ? noteMatch.effectCommand : '00';

                            return GestureDetector(
                              onTap: () {
                                _showTrackerCellEditor(context, track, stepIdx, colIdx, noteMatch);
                              },
                              child: Container(
                                width: 130,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasNote
                                      ? track.color.withOpacity(0.25)
                                      : DawTheme.controlBackground.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: hasNote ? track.color.withOpacity(0.6) : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  '$noteStr  $volStr  $fxStr',
                                  style: DawTheme.getDisplayFontStyle(
                                    color: hasNote ? DawTheme.textPrimary : DawTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: hasNote ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),

                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTrackerNote(int pitch) {
    if (pitch < 0) return '---';
    final names = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-'];
    final octave = (pitch ~/ 12) - 1;
    return '${names[pitch % 12]}$octave';
  }

  void _showTrackerCellEditor(
    BuildContext context,
    TrackChannel track,
    int stepIdx,
    int colIdx,
    Note existingNote,
  ) {
    int selectedPitch = existingNote.pitch != -1 ? existingNote.pitch : 60;
    double selectedVol = existingNote.pitch != -1 ? existingNote.velocity : 0.85;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DawTheme.panelBackground,
              title: Text(
                'ROW ${stepIdx.toString().padLeft(2, '0')} - COL 0${colIdx + 1}',
                style: TextStyle(color: DawTheme.primaryCyan, fontSize: 14),
              ),
              content: SizedBox(
                width: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NOTE PITCH:', style: TextStyle(color: DawTheme.textSecondary, fontSize: 12)),
                        Text(_formatTrackerNote(selectedPitch), style: const TextStyle(color: DawTheme.accentGold, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    EatBitsSlider(
                      value: selectedPitch.toDouble(),
                      min: 24,
                      max: 84,
                      defaultValue: 60,
                      label: 'Note Pitch',
                      activeColor: track.color,
                      onChanged: (val) {
                        setDialogState(() => selectedPitch = val.toInt());
                        widget.dawState.audioEngine.playNoteOrSample(
                          track: track,
                          midiNote: selectedPitch,
                          velocity: selectedVol,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('VELOCITY:', style: TextStyle(color: DawTheme.textSecondary, fontSize: 12)),
                        Text('${(selectedVol * 100).toInt()}%', style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    EatBitsSlider(
                      value: selectedVol,
                      min: 0.0,
                      max: 1.0,
                      defaultValue: 0.9,
                      label: 'Note Velocity',
                      activeColor: DawTheme.primaryCyan,
                      onChanged: (val) {
                        setDialogState(() => selectedVol = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (existingNote.pitch != -1)
                  TextButton(
                    onPressed: () {
                      widget.dawState.removeNote(track, existingNote.id);
                      Navigator.pop(context);
                    },
                    child: const Text('DELETE', style: TextStyle(color: DawTheme.muteColor)),
                  ),
                TextButton(
                  onPressed: () {
                    if (existingNote.pitch != -1) {
                      widget.dawState.removeNote(track, existingNote.id);
                    }
                    widget.dawState.addNote(
                      track,
                      Note(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        pitch: selectedPitch,
                        startStep: stepIdx.toDouble(),
                        durationSteps: 1.0,
                        velocity: selectedVol,
                        column: colIdx,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Text('SET NOTE', style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
