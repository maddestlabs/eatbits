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
  static const double keyHeight = 24.0;
  static const double stepWidth = 28.0;
  static const int minPitch = 24; // C1
  static const int maxPitch = 84; // C6
  static const int totalKeys = maxPitch - minPitch + 1;

  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  double _quantizeSnap = 1.0; // 1 step = 1/16th note

  @override
  void initState() {
    super.initState();
    // Scroll to C3 (MIDI note 48) on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verticalScroll.hasClients) {
        final targetY = (maxPitch - 60) * keyHeight;
        _verticalScroll.jumpTo(targetY.clamp(0, _verticalScroll.position.maxScrollExtent));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.dawState.activeTrack;
    final totalSteps = widget.dawState.activePattern.lengthSteps;

    return Column(
      children: [
        // Header Toolbar for Piano Roll
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                style: const TextStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),

              // View Mode Selector
              const Text('VIEW: ', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
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

              const Text('SNAP: ', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
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

        // Piano Roll Canvas Area
        Expanded(
          child: Row(
            children: [
              // Virtual Piano Keyboard (Left)
              SizedBox(
                width: 70,
                child: ListView.builder(
                  controller: _verticalScroll,
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

              // Note Grid Surface
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalSteps * stepWidth,
                    child: SingleChildScrollView(
                      controller: _verticalScroll,
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
                                  startStep: snappedStep,
                                  durationSteps: _quantizeSnap,
                                ),
                              );
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            // Grid Lines Painter
                            CustomPaint(
                              size: Size(totalSteps * stepWidth, totalKeys * keyHeight),
                              painter: PianoRollGridPainter(
                                totalSteps: totalSteps,
                                totalKeys: totalKeys,
                                stepWidth: stepWidth,
                                keyHeight: keyHeight,
                                currentStep: widget.dawState.isPlaying ? widget.dawState.currentStep : -1,
                              ),
                            ),

                            // Notes Overlay
                            ...track.notes.map((note) {
                              final keyIdx = maxPitch - note.pitch;
                              if (keyIdx < 0 || keyIdx >= totalKeys) return const SizedBox();

                              return Positioned(
                                left: note.startStep * stepWidth + 1,
                                top: keyIdx * keyHeight + 1,
                                width: (note.durationSteps * stepWidth) - 2,
                                height: keyHeight - 2,
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
                                      style: const TextStyle(color: DawTheme.backgroundDark, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
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

  bool _isBlackKey(int pitch) {
    final note = pitch % 12;
    return note == 1 || note == 3 || note == 6 || note == 8 || note == 10;
  }

  String _getNoteName(int pitch) {
    final names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (pitch ~/ 12) - 1;
    return '${names[pitch % 12]}$octave';
  }
}

class PianoRollGridPainter extends CustomPainter {
  final int totalSteps;
  final int totalKeys;
  final double stepWidth;
  final double keyHeight;
  final int currentStep;

  PianoRollGridPainter({
    required this.totalSteps,
    required this.totalKeys,
    required this.stepWidth,
    required this.keyHeight,
    required this.currentStep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = DawTheme.backgroundDark;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF1F2432)
      ..strokeWidth = 1.0;

    final barLinePaint = Paint()
      ..color = const Color(0xFF384259)
      ..strokeWidth = 1.5;

    // Draw horizontal key dividers
    for (int i = 0; i <= totalKeys; i++) {
      final y = i * keyHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw vertical step dividers
    for (int i = 0; i <= totalSteps; i++) {
      final x = i * stepWidth;
      final isBar = i % 4 == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isBar ? barLinePaint : linePaint);
    }

    // Draw playhead position highlight
    if (currentStep >= 0 && currentStep < totalSteps) {
      final playheadPaint = Paint()
        ..color = DawTheme.primaryCyan.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(currentStep * stepWidth, 0, stepWidth, size.height),
        playheadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PianoRollGridPainter oldDelegate) {
    return oldDelegate.currentStep != currentStep || oldDelegate.totalSteps != totalSteps;
  }
}
