import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';

class PianoRollView extends StatefulWidget {
  final DawState dawState;

  const PianoRollView({super.key, required this.dawState});

  @override
  State<PianoRollView> createState() => _PianoRollViewState();
}

class _PianoRollViewState extends State<PianoRollView> {
  static const int minPitch = 24; // C1
  static const int maxPitch = 84; // C6
  static const int totalKeys = maxPitch - minPitch + 1;

  static const double keyHeight = 24.0;
  static const double stepWidth = 28.0;
  static const int totalSteps = 32;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _keysScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();

  bool _isSyncingScroll = false;
  double _quantizeSnap = 1.0;

  @override
  void dispose() {
    _horizontalScroll.dispose();
    _keysScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  bool _isBlackKey(int midiPitch) {
    final noteInOctave = midiPitch % 12;
    return noteInOctave == 1 || noteInOctave == 3 || noteInOctave == 6 || noteInOctave == 8 || noteInOctave == 10;
  }

  String _getNoteName(int midiPitch) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final name = names[midiPitch % 12];
    final octave = (midiPitch / 12).floor() - 1;
    return '$name$octave';
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.dawState.activeTrack;

    return Column(
      children: [
        // Sub-Header Controls: Snap Quantize
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: DawTheme.panelHeader,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: track.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'PIANO ROLL: ${track.name.toUpperCase()}',
                style: TextStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),

              // View Mode Selector
              Text('VIEW: ', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
              ChoiceChip(
                label: const Text('PIANO ROLL', style: TextStyle(fontSize: 10)),
                selected: track.activeView == MusicViewType.pianoRoll,
                selectedColor: DawTheme.primaryCyan,
                onSelected: (_) {
                  widget.dawState.setTrackActiveView(track, MusicViewType.pianoRoll);
                },
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('TRACKER', style: TextStyle(fontSize: 10)),
                selected: track.activeView == MusicViewType.tracker,
                selectedColor: DawTheme.secondaryMagenta,
                onSelected: (_) {
                  widget.dawState.setTrackActiveView(track, MusicViewType.tracker);
                },
              ),
              const SizedBox(width: 12),

              Text('SNAP: ', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
              DropdownButton<double>(
                value: _quantizeSnap,
                dropdownColor: DawTheme.panelBackground,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 1.0, child: Text('1/16', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 2.0, child: Text('1/8', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 4.0, child: Text('1/4', style: TextStyle(fontSize: 11))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _quantizeSnap = val);
                },
              ),
            ],
          ),
        ),

        // Piano Roll Canvas Area (Synchronized Keys & Grid Scrolling)
        Expanded(
          child: Row(
            children: [
              // Virtual Piano Keyboard Column (Left)
              SizedBox(
                width: 70,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (!_isSyncingScroll && notification is ScrollUpdateNotification) {
                      _isSyncingScroll = true;
                      if (_gridScrollController.hasClients) {
                        _gridScrollController.jumpTo(_keysScrollController.offset);
                      }
                      _isSyncingScroll = false;
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    controller: _keysScrollController,
                    itemCount: totalKeys,
                    itemBuilder: (context, idx) {
                      final pitch = maxPitch - idx;
                      final isBlackKey = _isBlackKey(pitch);
                      final noteName = _getNoteName(pitch);

                      return GestureDetector(
                        onTapDown: (_) {
                          widget.dawState.audioEngine.playNoteOrSample(
                            track: track,
                            midiNote: pitch,
                            velocity: 0.9,
                          );
                        },
                        child: Container(
                          height: keyHeight,
                          padding: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isBlackKey ? const Color(0xFF1E222D) : const Color(0xFFDCDFE5),
                            border: Border(
                              bottom: BorderSide(color: isBlackKey ? Colors.black45 : Colors.grey.shade400, width: 0.5),
                            ),
                          ),
                          alignment: Alignment.centerRight,
                          child: Text(
                            noteName,
                            style: TextStyle(
                              color: isBlackKey ? Colors.white70 : Colors.black87,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Note Grid Surface (Right, Synced Vertical Scroll)
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalSteps * stepWidth,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (!_isSyncingScroll && notification is ScrollUpdateNotification) {
                          _isSyncingScroll = true;
                          if (_keysScrollController.hasClients) {
                            _keysScrollController.jumpTo(_gridScrollController.offset);
                          }
                          _isSyncingScroll = false;
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _gridScrollController,
                        scrollDirection: Axis.vertical,
                        child: GestureDetector(
                          onTapUp: (details) {
                            final localPos = details.localPosition;

                            final int stepIdx = (localPos.dx / stepWidth).floor();
                            final int keyIdx = (localPos.dy / keyHeight).floor();
                            final int pitch = maxPitch - keyIdx;

                            if (stepIdx >= 0 && stepIdx < totalSteps && pitch >= minPitch && pitch <= maxPitch) {
                              final snappedStep = (stepIdx / _quantizeSnap).floor() * _quantizeSnap;
                              
                              // Check if note exists to delete, or create new note
                              final existingIndex = track.notes.indexWhere((n) =>
                                  n.pitch == pitch && n.startStep <= snappedStep && (n.startStep + n.durationSteps) > snappedStep);

                              if (existingIndex != -1) {
                                widget.dawState.removeNote(track, track.notes[existingIndex].id);
                              } else {
                                widget.dawState.addNote(
                                  track,
                                  Note(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    pitch: pitch,
                                    startStep: snappedStep.toDouble(),
                                    durationSteps: _quantizeSnap,
                                    velocity: 0.85,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            height: totalKeys * keyHeight,
                            color: DawTheme.backgroundDark,
                            child: Stack(
                              children: [
                                // Background Grid Lines & Piano Rows
                                Column(
                                  children: List.generate(totalKeys, (idx) {
                                    final pitch = maxPitch - idx;
                                    final isBlackKey = _isBlackKey(pitch);

                                    return Container(
                                      height: keyHeight,
                                      decoration: BoxDecoration(
                                        color: isBlackKey ? Colors.white.withOpacity(0.02) : Colors.transparent,
                                        border: Border(
                                          bottom: BorderSide(color: Colors.white.withOpacity(0.04), width: 1),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                // Vertical Bar/Step Grid Lines
                                Row(
                                  children: List.generate(totalSteps, (stepIdx) {
                                    final isBarHeader = stepIdx % 4 == 0;
                                    return Container(
                                      width: stepWidth,
                                      height: totalKeys * keyHeight,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: isBarHeader ? DawTheme.primaryCyan.withOpacity(0.3) : Colors.white.withOpacity(0.04),
                                            width: isBarHeader ? 1.5 : 1.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                // Playhead Position Line
                                Positioned(
                                  left: widget.dawState.currentStep * stepWidth,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 2,
                                    color: DawTheme.primaryCyan,
                                  ),
                                ),

                                // Render Note Events Blocks
                                ...track.notes.map((note) {
                                  final keyIdx = maxPitch - note.pitch;
                                  if (keyIdx < 0 || keyIdx >= totalKeys) return const SizedBox();

                                  return Positioned(
                                    left: note.startStep * stepWidth + 1,
                                    top: keyIdx * keyHeight + 1,
                                    width: (note.durationSteps * stepWidth) - 2,
                                    height: keyHeight - 2,
                                    child: GestureDetector(
                                      onLongPress: () {
                                        widget.dawState.removeNote(track, note.id);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: track.color,
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(color: track.color.withOpacity(0.5), blurRadius: 4),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getNoteName(note.pitch),
                                            style: TextStyle(color: DawTheme.backgroundDark, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
