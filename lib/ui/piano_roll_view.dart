import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';

enum PianoRollToolMode { edit, pan }

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

  PianoRollToolMode _toolMode = PianoRollToolMode.edit;

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

  void _syncKeysScroll() {
    if (!_isSyncingScroll && _keysScrollController.hasClients && _gridScrollController.hasClients) {
      _isSyncingScroll = true;
      _keysScrollController.jumpTo(_gridScrollController.offset);
      _isSyncingScroll = false;
    }
  }

  void _zoom(double factor) {
    final oldStepWidth = _stepWidth;
    final oldKeyHeight = _keyHeight;

    final newStepWidth = (_stepWidth * factor).clamp(12.0, 80.0);
    final newKeyHeight = (_keyHeight * factor).clamp(14.0, 48.0);

    setState(() {
      _stepWidth = newStepWidth;
      _keyHeight = newKeyHeight;
    });

    _adjustScrollForZoom(oldStepWidth, newStepWidth, oldKeyHeight, newKeyHeight);
  }

  void _resetZoom() {
    final oldStepWidth = _stepWidth;
    final oldKeyHeight = _keyHeight;

    setState(() {
      _stepWidth = 28.0;
      _keyHeight = 24.0;
    });

    _adjustScrollForZoom(oldStepWidth, 28.0, oldKeyHeight, 24.0);
  }

  void _adjustScrollForZoom(double oldWidth, double newWidth, double oldHeight, double newHeight) {
    if (oldWidth > 0 && _horizontalScroll.hasClients) {
      final ratioX = newWidth / oldWidth;
      final targetX = (_horizontalScroll.offset * ratioX).clamp(0.0, _horizontalScroll.position.maxScrollExtent);
      _horizontalScroll.jumpTo(targetX);
    }

    if (oldHeight > 0 && _gridScrollController.hasClients) {
      final ratioY = newHeight / oldHeight;
      final targetY = (_gridScrollController.offset * ratioY).clamp(0.0, _gridScrollController.position.maxScrollExtent);
      _gridScrollController.jumpTo(targetY);
      _syncKeysScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.dawState.activeTrack;
    final snap = widget.dawState.quantizeSnap;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Sub-toolbar for Piano Roll (Tool Selection & Zoom Controls)
        Container(
          height: 34,
          color: DawTheme.panelBackground,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            children: [
              // Tool Mode Segmented Control (EDIT vs PAN)
              Container(
                decoration: BoxDecoration(
                  color: DawTheme.panelHeader,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: DawTheme.textMuted.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _toolMode = PianoRollToolMode.edit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _toolMode == PianoRollToolMode.edit ? DawTheme.primaryCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 13,
                              color: _toolMode == PianoRollToolMode.edit ? DawTheme.backgroundDark : DawTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'DRAW/EDIT',
                              style: TextStyle(
                                color: _toolMode == PianoRollToolMode.edit ? DawTheme.backgroundDark : DawTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _toolMode = PianoRollToolMode.pan),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _toolMode == PianoRollToolMode.pan ? DawTheme.secondaryMagenta : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.pan_tool,
                              size: 13,
                              color: _toolMode == PianoRollToolMode.pan ? Colors.white : DawTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'PAN/ZOOM',
                              style: TextStyle(
                                color: _toolMode == PianoRollToolMode.pan ? Colors.white : DawTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              if (!isMobile)
                Text(
                  _toolMode == PianoRollToolMode.edit ? '1-finger edit / 2-finger pan & zoom' : '1-finger pan / 2-finger zoom',
                  style: TextStyle(color: DawTheme.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
                ),

              const Spacer(),

              // Quick Zoom Controls
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 16),
                color: DawTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Zoom Out',
                onPressed: () => _zoom(0.8),
              ),
              IconButton(
                icon: const Icon(Icons.aspect_ratio, size: 14),
                color: DawTheme.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Reset Zoom',
                onPressed: _resetZoom,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 16),
                color: DawTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Zoom In',
                onPressed: () => _zoom(1.25),
              ),
            ],
          ),
        ),

        // Main Piano Roll Canvas & Keyboard
        Expanded(
          child: GestureDetector(
            onScaleStart: (details) {
              _baseStepWidth = _stepWidth;
              _baseKeyHeight = _keyHeight;
            },
            onScaleUpdate: (details) {
              if (details.pointerCount >= 2) {
                // 2-Finger Pinch-to-Zoom & Pan
                final oldWidth = _stepWidth;
                final oldHeight = _keyHeight;

                final newWidth = (_baseStepWidth * details.horizontalScale).clamp(12.0, 80.0);
                final newHeight = (_baseKeyHeight * details.verticalScale).clamp(14.0, 48.0);

                setState(() {
                  _stepWidth = newWidth;
                  _keyHeight = newHeight;
                });

                _adjustScrollForZoom(oldWidth, newWidth, oldHeight, newHeight);

                // Handle focal point panning during 2-finger pinch
                if (details.focalPointDelta != Offset.zero) {
                  if (_horizontalScroll.hasClients) {
                    final targetX = (_horizontalScroll.offset - details.focalPointDelta.dx)
                        .clamp(0.0, _horizontalScroll.position.maxScrollExtent);
                    _horizontalScroll.jumpTo(targetX);
                  }
                  if (_gridScrollController.hasClients) {
                    final targetY = (_gridScrollController.offset - details.focalPointDelta.dy)
                        .clamp(0.0, _gridScrollController.position.maxScrollExtent);
                    _gridScrollController.jumpTo(targetY);
                    _syncKeysScroll();
                  }
                }
              } else if (_toolMode == PianoRollToolMode.pan && details.pointerCount == 1) {
                // 1-Finger Panning in PAN mode
                if (_horizontalScroll.hasClients && details.focalPointDelta.dx != 0) {
                  final targetX = (_horizontalScroll.offset - details.focalPointDelta.dx)
                      .clamp(0.0, _horizontalScroll.position.maxScrollExtent);
                  _horizontalScroll.jumpTo(targetX);
                }
                if (_gridScrollController.hasClients && details.focalPointDelta.dy != 0) {
                  final targetY = (_gridScrollController.offset - details.focalPointDelta.dy)
                      .clamp(0.0, _gridScrollController.position.maxScrollExtent);
                  _gridScrollController.jumpTo(targetY);
                  _syncKeysScroll();
                }
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
                    physics: _toolMode == PianoRollToolMode.edit ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: totalSteps * _stepWidth,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            _syncKeysScroll();
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          controller: _gridScrollController,
                          scrollDirection: Axis.vertical,
                          physics: _toolMode == PianoRollToolMode.edit ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
                          child: GestureDetector(
                            onTapUp: (details) {
                              if (_toolMode != PianoRollToolMode.edit) return;

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
                                          color: isBlackKey
                                              ? (DawTheme.isLight ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.02))
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: DawTheme.isLight ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                                              width: 1,
                                            ),
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
                                              color: isBarHeader
                                                  ? DawTheme.primaryCyan.withOpacity(0.45)
                                                  : (DawTheme.isLight ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.04)),
                                              width: isBarHeader ? 1.5 : 1.0,
                                            ),
                                            right: BorderSide(
                                              color: DawTheme.isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.04),
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
                                    final handleWidth = math.max(20.0, _stepWidth * 0.35);

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
                                                if (_toolMode == PianoRollToolMode.edit) {
                                                  widget.dawState.removeNote(track, note.id);
                                                }
                                              },
                                              onPanStart: (details) {
                                                if (_toolMode == PianoRollToolMode.edit) {
                                                  _activeMoveNoteId = note.id;
                                                  _moveStartStep = note.startStep;
                                                  _moveStartPitch = note.pitch;
                                                  _moveStartPos = details.globalPosition;
                                                }
                                              },
                                              onPanUpdate: (details) {
                                                if (_toolMode != PianoRollToolMode.edit ||
                                                    _activeMoveNoteId != note.id ||
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
                                                if (_toolMode == PianoRollToolMode.edit && _activeMoveNoteId == note.id) {
                                                  _activeMoveNoteId = null;
                                                  widget.dawState.audioEngine.playNoteOrSample(
                                                    track: track,
                                                    midiNote: note.pitch,
                                                    velocity: note.velocity,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: track.color,
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(color: track.color.withOpacity(0.5), blurRadius: 4),
                                                  ],
                                                ),
                                                padding: EdgeInsets.only(right: math.min(handleWidth, noteWidth * 0.4)),
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

                                          // Right-Edge Resize Handle (Enlarged for Mobile Touch)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            bottom: 0,
                                            width: math.min(handleWidth, noteWidth),
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onPanStart: (details) {
                                                if (_toolMode == PianoRollToolMode.edit) {
                                                  _activeResizeNoteId = note.id;
                                                  _resizeStartDuration = note.durationSteps;
                                                  _resizeStartPos = details.globalPosition;
                                                }
                                              },
                                              onPanUpdate: (details) {
                                                if (_toolMode != PianoRollToolMode.edit ||
                                                    _activeResizeNoteId != note.id ||
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
                                                  color: Colors.white.withOpacity(0.35),
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(4),
                                                    bottomRight: Radius.circular(4),
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.drag_handle, size: 12, color: Colors.black87),
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
          ),
        ),
      ],
    );
  }
}
