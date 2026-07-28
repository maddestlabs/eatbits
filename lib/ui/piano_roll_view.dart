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
  static const int totalSteps = 32;

  double _stepWidth = 28.0;
  double _keyHeight = 24.0;
  double _baseStepWidth = 28.0;
  double _baseKeyHeight = 24.0;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _keysScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();

  bool _isSyncingScroll = false;

  // Move / Resize tracking variables
  String? _activeMoveNoteId;
  double? _moveStartStep;
  int? _moveStartPitch;
  Offset? _moveStartPos;

  String? _activeResizeNoteId;
  double? _resizeStartDuration;
  Offset? _resizeStartPos;

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
    final snap = widget.dawState.quantizeSnap;

    return GestureDetector(
      onScaleStart: (details) {
        _baseStepWidth = _stepWidth;
        _baseKeyHeight = _keyHeight;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          setState(() {
            _stepWidth = (_baseStepWidth * details.horizontalScale).clamp(12.0, 80.0);
            _keyHeight = (_baseKeyHeight * details.verticalScale).clamp(14.0, 48.0);
          });
        }
      },
      child: Row(
        children: [
          // Virtual Piano Keyboard Column (Left)
          SizedBox(
            width: 70,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                controller: _keysScrollController,
                itemCount: totalKeys,
                itemBuilder: (context, idx) {
                  final pitch = maxPitch - idx;
                  final isBlackKey = _isBlackKey(pitch);
                  final noteName = _getNoteName(pitch);

                  return GestureDetector(
                    onTapDown: (details) {
                      const double keyWidth = 70.0;
                      final double normalizedX = (details.localPosition.dx / keyWidth).clamp(0.0, 1.0);
                      final double velocity = (0.15 + 0.85 * normalizedX).clamp(0.15, 1.0);
                      widget.dawState.audioEngine.playNoteOrSample(
                        track: track,
                        midiNote: pitch,
                        velocity: velocity,
                      );
                    },
                    child: Container(
                      height: _keyHeight,
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
                          fontSize: (_keyHeight * 0.38).clamp(8.0, 12.0),
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
                width: totalSteps * _stepWidth,
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
                        final int stepIdx = (localPos.dx / _stepWidth).floor();
                        final int keyIdx = (localPos.dy / _keyHeight).floor();
                        final int pitch = maxPitch - keyIdx;

                        if (stepIdx >= 0 && stepIdx < totalSteps && pitch >= minPitch && pitch <= maxPitch) {
                          double snappedStep = stepIdx.toDouble();
                          double duration = 1.0;
                          if (snap > 0) {
                            snappedStep = (stepIdx / snap).floor() * snap;
                            duration = snap;
                          }

                          final existingIndex = track.notes.indexWhere((n) =>
                              n.pitch == pitch && n.startStep <= snappedStep && (n.startStep + n.durationSteps) > snappedStep);

                          if (existingIndex == -1) {
                            widget.dawState.addNote(
                              track,
                              Note(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                pitch: pitch,
                                startStep: snappedStep,
                                durationSteps: duration,
                                velocity: 0.85,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: totalKeys * _keyHeight,
                        color: DawTheme.backgroundDark,
                        child: Stack(
                          children: [
                            // Background Grid Lines & Piano Rows
                            Column(
                              children: List.generate(totalKeys, (idx) {
                                final pitch = maxPitch - idx;
                                final isBlackKey = _isBlackKey(pitch);

                                return Container(
                                  height: _keyHeight,
                                  decoration: BoxDecoration(
                                    color: isBlackKey ? Colors.white.withOpacity(0.02) : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.white.withOpacity(0.04), width: 1),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            // Vertical Bar/Step Grid Lines (Highlighting starts at Column 0)
                            Row(
                              children: List.generate(totalSteps, (stepIdx) {
                                final isBarHeader = stepIdx % 4 == 0;
                                return Container(
                                  width: _stepWidth,
                                  height: totalKeys * _keyHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: isBarHeader ? DawTheme.primaryCyan.withOpacity(0.35) : Colors.white.withOpacity(0.04),
                                        width: isBarHeader ? 1.5 : 1.0,
                                      ),
                                      right: BorderSide(
                                        color: Colors.white.withOpacity(0.04),
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            // Playhead Position Line
                            Positioned(
                              left: widget.dawState.currentStep * _stepWidth,
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

                              final noteLeft = note.startStep * _stepWidth + 1;
                              final noteTop = keyIdx * _keyHeight + 1;
                              final noteWidth = ((note.durationSteps * _stepWidth) - 2).clamp(8.0, double.infinity);
                              final noteHeight = _keyHeight - 2;

                              return Positioned(
                                left: noteLeft,
                                top: noteTop,
                                width: noteWidth,
                                height: noteHeight,
                                child: Stack(
                                  children: [
                                    // Main Note Body (Move & Double-Tap Delete)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onDoubleTap: () {
                                          widget.dawState.removeNote(track, note.id);
                                        },
                                        onPanStart: (details) {
                                          _activeMoveNoteId = note.id;
                                          _moveStartStep = note.startStep;
                                          _moveStartPitch = note.pitch;
                                          _moveStartPos = details.globalPosition;
                                        },
                                        onPanUpdate: (details) {
                                          if (_activeMoveNoteId != note.id ||
                                              _moveStartStep == null ||
                                              _moveStartPitch == null ||
                                              _moveStartPos == null) return;

                                          final dxSteps = (details.globalPosition.dx - _moveStartPos!.dx) / _stepWidth;
                                          final dyPitches = -((details.globalPosition.dy - _moveStartPos!.dy) / _keyHeight).round();

                                          double candidateStep = (_moveStartStep! + dxSteps).clamp(0.0, totalSteps - note.durationSteps);
                                          if (snap > 0) {
                                            candidateStep = (candidateStep / snap).round() * snap;
                                          }
                                          int candidatePitch = (_moveStartPitch! + dyPitches).clamp(minPitch, maxPitch);

                                          widget.dawState.updateNote(
                                            track,
                                            note.copyWith(startStep: candidateStep, pitch: candidatePitch),
                                          );
                                        },
                                        onPanEnd: (_) {
                                          _activeMoveNoteId = null;
                                          widget.dawState.audioEngine.playNoteOrSample(
                                            track: track,
                                            midiNote: note.pitch,
                                            velocity: note.velocity,
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: track.color,
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(color: track.color.withOpacity(0.5), blurRadius: 4),
                                            ],
                                          ),
                                          padding: const EdgeInsets.only(right: 12),
                                          child: Center(
                                            child: Text(
                                              _getNoteName(note.pitch),
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: DawTheme.backgroundDark,
                                                fontSize: (_keyHeight * 0.38).clamp(8.0, 11.0),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Right-Edge Resize Handle
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      width: 14,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onPanStart: (details) {
                                          _activeResizeNoteId = note.id;
                                          _resizeStartDuration = note.durationSteps;
                                          _resizeStartPos = details.globalPosition;
                                        },
                                        onPanUpdate: (details) {
                                          if (_activeResizeNoteId != note.id ||
                                              _resizeStartDuration == null ||
                                              _resizeStartPos == null) return;

                                          final dxSteps = (details.globalPosition.dx - _resizeStartPos!.dx) / _stepWidth;
                                          final double minDur = snap > 0 ? snap : 0.25;
                                          double candidateDur = (_resizeStartDuration! + dxSteps).clamp(minDur, totalSteps - note.startStep);

                                          if (snap > 0) {
                                            candidateDur = (candidateDur / snap).round() * snap;
                                            if (candidateDur < snap) candidateDur = snap;
                                          }

                                          widget.dawState.updateNote(
                                            track,
                                            note.copyWith(durationSteps: candidateDur),
                                          );
                                        },
                                        onPanEnd: (_) {
                                          _activeResizeNoteId = null;
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(4),
                                              bottomRight: Radius.circular(4),
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.drag_handle, size: 10, color: Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}
