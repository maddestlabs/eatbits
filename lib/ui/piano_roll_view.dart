import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/eats_theme.dart';
import 'widgets/compact_value_dialog.dart';

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
  static const int totalSteps = 64; // Extended horizontal grid (16 bars of 4 steps)

  double _stepWidth = 28.0;
  double _keyHeight = 24.0;
  double _baseStepWidth = 28.0;
  double _baseKeyHeight = 24.0;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _keysScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();

  bool _isSyncingScroll = false;
  String? _selectedNoteId;

  // Draggable Note Properties dialog state
  Offset? _notePropertiesOffset;
  String? _draggedNoteId;

  // Move tracking variables
  String? _activeMoveNoteId;
  double? _moveStartStep;
  int? _moveStartPitch;
  Offset? _moveStartPos;

  // Resize tracking variables
  String? _activeResizeNoteId;
  double? _resizeStartDuration;
  Offset? _resizeStartPos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerViewOnNotesOrDefault();
      }
    });
  }

  void _centerViewOnNotesOrDefault({bool animate = false}) {
    if (!_gridScrollController.hasClients) return;
    final track = widget.dawState.activeTrack;
    final maxScroll = _gridScrollController.position.maxScrollExtent;
    final viewportH = _gridScrollController.position.viewportDimension;

    double targetY;

    if (track.notes.isNotEmpty) {
      int minP = 127;
      int maxP = 0;
      for (final n in track.notes) {
        if (n.pitch < minP) minP = n.pitch;
        if (n.pitch > maxP) maxP = n.pitch;
      }
      final midPitch = (minP + maxP) / 2.0;
      final midKeyIdx = maxPitch - midPitch;
      targetY = (midKeyIdx * _keyHeight) - (viewportH / 2) + (_keyHeight / 2);
    } else {
      // Default to showing C4 (MIDI pitch 60) and downward
      const defaultPitch = 60; // C4
      final c4KeyIdx = maxPitch - defaultPitch;
      targetY = c4KeyIdx * _keyHeight;
    }

    targetY = targetY.clamp(0.0, maxScroll);

    if (animate) {
      _gridScrollController.animateTo(
        targetY,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _gridScrollController.jumpTo(targetY);
    }
    _syncKeysScroll();
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncKeysScroll();
      }
    });
  }

  void _ensureNoteAndMenuVisible(Note note, {bool forceVerticalScroll = false}) {
    if (!mounted) return;

    final keyIdx = maxPitch - note.pitch;
    final noteTop = keyIdx * _keyHeight + 1;
    final noteLeft = note.startStep * _stepWidth + 1;
    final noteWidth = ((note.durationSteps * _stepWidth) - 2).clamp(8.0, double.infinity);

    // Vertical scroll check (only when forceVerticalScroll is true, e.g. for Octave Transpose +12/-12)
    if (forceVerticalScroll && _gridScrollController.hasClients) {
      final scrollY = _gridScrollController.offset;
      final viewportH = _gridScrollController.position.viewportDimension;
      final maxScrollY = _gridScrollController.position.maxScrollExtent;

      double? targetScrollY;
      if (noteTop - 100 < scrollY) {
        targetScrollY = (noteTop - 110).clamp(0.0, maxScrollY);
      } else if (noteTop + _keyHeight + 100 > scrollY + viewportH) {
        targetScrollY = (noteTop + _keyHeight + 110 - viewportH).clamp(0.0, maxScrollY);
      }

      if (targetScrollY != null && (targetScrollY - scrollY).abs() > 2) {
        _gridScrollController.animateTo(
          targetScrollY,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        _syncKeysScroll();
      }
    }

    // Horizontal scroll check
    if (_horizontalScroll.hasClients) {
      final scrollX = _horizontalScroll.offset;
      final viewportW = _horizontalScroll.position.viewportDimension;
      final maxScrollX = _horizontalScroll.position.maxScrollExtent;

      double? targetScrollX;
      if (noteLeft < scrollX + 30) {
        targetScrollX = (noteLeft - 40).clamp(0.0, maxScrollX);
      } else if (noteLeft + noteWidth + 260 > scrollX + viewportW) {
        targetScrollX = (noteLeft + noteWidth + 280 - viewportW).clamp(0.0, maxScrollX);
      }

      if (targetScrollX != null && (targetScrollX - scrollX).abs() > 2) {
        _horizontalScroll.animateTo(
          targetScrollX,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _selectPreviousNote(TrackChannel track) {
    if (track.notes.isEmpty) return;
    final sorted = List<Note>.from(track.notes)..sort((a, b) {
      final stepComp = a.startStep.compareTo(b.startStep);
      if (stepComp != 0) return stepComp;
      return a.pitch.compareTo(b.pitch);
    });

    int currIdx = sorted.indexWhere((n) => n.id == _selectedNoteId);
    int targetIdx;
    if (currIdx <= 0) {
      targetIdx = sorted.length - 1;
    } else {
      targetIdx = currIdx - 1;
    }

    final note = sorted[targetIdx];
    setState(() {
      _selectedNoteId = note.id;
    });
    widget.dawState.audioEngine.playNoteOrSample(
      track: track,
      midiNote: note.pitch,
      velocity: note.velocity,
    );
    _ensureNoteAndMenuVisible(note);
  }

  void _selectNextNote(TrackChannel track) {
    if (track.notes.isEmpty) return;
    final sorted = List<Note>.from(track.notes)..sort((a, b) {
      final stepComp = a.startStep.compareTo(b.startStep);
      if (stepComp != 0) return stepComp;
      return a.pitch.compareTo(b.pitch);
    });

    int currIdx = sorted.indexWhere((n) => n.id == _selectedNoteId);
    int targetIdx;
    if (currIdx == -1 || currIdx >= sorted.length - 1) {
      targetIdx = 0;
    } else {
      targetIdx = currIdx + 1;
    }

    final note = sorted[targetIdx];
    setState(() {
      _selectedNoteId = note.id;
    });
    widget.dawState.audioEngine.playNoteOrSample(
      track: track,
      midiNote: note.pitch,
      velocity: note.velocity,
    );
    _ensureNoteAndMenuVisible(note);
  }

  void _transposeSelectedNote(TrackChannel track, Note note, int semitones) {
    final newPitch = (note.pitch + semitones).clamp(minPitch, maxPitch);
    if (newPitch != note.pitch) {
      final isOctave = semitones.abs() == 12;
      if (isOctave) {
        _notePropertiesOffset = null; // Auto-reposition dialog to follow octave transpose!
      }
      final updatedNote = note.copyWith(pitch: newPitch);
      widget.dawState.updateNote(track, updatedNote);
      widget.dawState.audioEngine.playNoteOrSample(
        track: track,
        midiNote: newPitch,
        velocity: note.velocity,
      );
      _ensureNoteAndMenuVisible(updatedNote, forceVerticalScroll: isOctave);
    }
  }

  void _changeSelectedNotePosition(TrackChannel track, Note note, double newStartStep) {
    final maxStep = (totalSteps - note.durationSteps).clamp(0.0, double.infinity);
    final clamped = newStartStep.clamp(0.0, maxStep);
    double snappedStep = clamped;
    final snap = widget.dawState.quantizeSnap;
    if (snap > 0) {
      snappedStep = (clamped / snap).round() * snap;
      snappedStep = snappedStep.clamp(0.0, maxStep);
    }
    widget.dawState.updateNote(track, note.copyWith(startStep: snappedStep));
  }

  void _changeSelectedNoteDuration(TrackChannel track, Note note, double newDur) {
    final minDur = widget.dawState.quantizeSnap > 0 ? widget.dawState.quantizeSnap : 0.25;
    final clamped = newDur.clamp(minDur, totalSteps - note.startStep);
    widget.dawState.updateNote(track, note.copyWith(durationSteps: clamped));
  }

  void _changeSelectedNoteVelocity(TrackChannel track, Note note, double newVel) {
    final clamped = newVel.clamp(0.05, 1.0);
    widget.dawState.updateNote(track, note.copyWith(velocity: clamped));
  }

  void _openManualPositionDialog(BuildContext context, TrackChannel track, Note note) {
    showCompactValueEditDialog(
      context: context,
      title: 'EDIT NOTE POSITION (STEP)',
      initialValue: note.startStep.toStringAsFixed(2),
      minMaxHint: 'Range: Step 0.0 to ${(totalSteps - note.durationSteps).toStringAsFixed(1)}',
      accentColor: EatsTheme.accentGold,
      onSubmit: (val) {
        final parsed = double.tryParse(val);
        if (parsed != null) {
          _changeSelectedNotePosition(track, note, parsed);
        }
      },
    );
  }

  void _openManualDurationDialog(BuildContext context, TrackChannel track, Note note) {
    showCompactValueEditDialog(
      context: context,
      title: 'EDIT NOTE DURATION (STEPS)',
      initialValue: note.durationSteps.toStringAsFixed(2),
      minMaxHint: 'Min: 0.25 steps, Max: ${(totalSteps - note.startStep).toStringAsFixed(1)} steps',
      accentColor: EatsTheme.primaryCyan,
      onSubmit: (val) {
        final parsed = double.tryParse(val);
        if (parsed != null && parsed > 0) {
          _changeSelectedNoteDuration(track, note, parsed);
        }
      },
    );
  }

  void _openManualVelocityDialog(BuildContext context, TrackChannel track, Note note) {
    final velPercent = (note.velocity * 100).round();
    showCompactValueEditDialog(
      context: context,
      title: 'EDIT NOTE VELOCITY (%)',
      initialValue: '$velPercent',
      minMaxHint: 'Range: 5% to 100%',
      accentColor: EatsTheme.accentGold,
      onSubmit: (val) {
        final parsed = double.tryParse(val);
        if (parsed != null) {
          final normalized = (parsed / 100.0).clamp(0.05, 1.0);
          _changeSelectedNoteVelocity(track, note, normalized);
          widget.dawState.audioEngine.playNoteOrSample(
            track: track,
            midiNote: note.pitch,
            velocity: normalized,
          );
        }
      },
    );
  }

  Widget _buildCompactButton(String label, VoidCallback onTap, {String? tooltip}) {
    final btn = InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: EatsTheme.controlBackground,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: EatsTheme.textMuted.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: EatsTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  Widget _buildSelectedNoteHoverCard(TrackChannel track, Note note, double snap, double noteLeft, double noteTop, double noteWidth, double noteHeight) {
    final minDur = snap > 0 ? snap : 0.25;
    final velPercent = (note.velocity * 100).round();

    const double cardWidth = 250.0;
    const double cardHeight = 220.0;

    if (_draggedNoteId != note.id) {
      _draggedNoteId = note.id;
      _notePropertiesOffset = null;
    }

    // Get visible viewport offsets & dimensions to ensure dialog is 100% visible on screen
    final scrollY = _gridScrollController.hasClients ? _gridScrollController.offset : 0.0;
    final viewportH = _gridScrollController.hasClients ? _gridScrollController.position.viewportDimension : 400.0;
    final scrollX = _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    final viewportW = _horizontalScroll.hasClients ? _horizontalScroll.position.viewportDimension : 600.0;

    final minVisibleTop = scrollY + 4.0;
    final maxVisibleTop = math.max(minVisibleTop, scrollY + viewportH - cardHeight - 4.0);
    final minVisibleLeft = scrollX + 4.0;
    final maxVisibleLeft = math.max(minVisibleLeft, scrollX + viewportW - cardWidth - 4.0);

    double cardTop;
    double cardLeft = noteLeft;

    final spaceAboveInViewport = noteTop - scrollY - 8.0;
    final spaceBelowInViewport = (scrollY + viewportH) - (noteTop + noteHeight) - 8.0;

    if (spaceAboveInViewport >= cardHeight) {
      // Place ABOVE note
      cardTop = noteTop - cardHeight - 8.0;
    } else if (spaceBelowInViewport >= cardHeight) {
      // Place BELOW note
      cardTop = noteTop + noteHeight + 8.0;
    } else {
      // Space above & below are tight in viewport -> place alongside note
      cardTop = (noteTop - 20.0).clamp(minVisibleTop, maxVisibleTop);
      if (noteLeft + noteWidth + cardWidth + 8.0 <= scrollX + viewportW) {
        cardLeft = noteLeft + noteWidth + 8.0;
      } else if (noteLeft - cardWidth - 8.0 >= scrollX) {
        cardLeft = noteLeft - cardWidth - 8.0;
      }
    }

    if (_notePropertiesOffset != null) {
      cardLeft += _notePropertiesOffset!.dx;
      cardTop += _notePropertiesOffset!.dy;
    }

    // Strictly clamp position within visible viewport bounds to guarantee zero clipping
    cardLeft = cardLeft.clamp(minVisibleLeft, maxVisibleLeft);
    cardTop = cardTop.clamp(minVisibleTop, maxVisibleTop);

    final maxPosStep = (totalSteps - note.durationSteps).clamp(0.0, double.infinity);
    final nudgeStep = snap > 0 ? snap : 1.0;

    return Positioned(
      left: cardLeft,
      top: cardTop,
      width: cardWidth,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: EatsTheme.panelBackground.withOpacity(0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: EatsTheme.primaryCyan, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Draggable Header (Note Info Badge, Drag Handle & Action Buttons)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  setState(() {
                    _notePropertiesOffset = (_notePropertiesOffset ?? Offset.zero) + details.delta;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: EatsTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: track.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_getNoteName(note.pitch)} @ Step ${note.startStep.toStringAsFixed(note.startStep % 1 == 0 ? 0 : 1)}',
                        style: TextStyle(
                          color: EatsTheme.backgroundDark,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        widget.dawState.removeNote(track, note.id);
                        setState(() => _selectedNoteId = null);
                      },
                      child: Tooltip(
                        message: 'Delete Note',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_forever, size: 14, color: Colors.redAccent),
                              SizedBox(width: 3),
                              Text(
                                'DEL',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: EatsTheme.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      tooltip: 'Close Menu',
                      onPressed: () => setState(() => _selectedNoteId = null),
                    ),
                  ],
                ),
              ),
              const Divider(height: 10, thickness: 0.5, color: Colors.white24),

              // Row 2: Pitch Transpose Buttons
              Row(
                children: [
                  Text('PITCH:', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _buildCompactButton('-12', () => _transposeSelectedNote(track, note, -12), tooltip: '-1 Octave'),
                  _buildCompactButton('-1', () => _transposeSelectedNote(track, note, -1), tooltip: '-1 Semitone'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _getNoteName(note.pitch),
                      style: TextStyle(color: EatsTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildCompactButton('+1', () => _transposeSelectedNote(track, note, 1), tooltip: '+1 Semitone'),
                  _buildCompactButton('+12', () => _transposeSelectedNote(track, note, 12), tooltip: '+1 Octave'),
                ],
              ),
              const SizedBox(height: 6),

              // Row 3: Note Position (Step Start) Controls & Nudge Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: () => _openManualPositionDialog(context, track, note),
                    child: Tooltip(
                      message: 'Long-press for manual numeric step input',
                      child: Row(
                        children: [
                          Text('POS: ', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(
                            'Step ${note.startStep.toStringAsFixed(note.startStep % 1 == 0 ? 0 : 1)}',
                            style: TextStyle(color: EatsTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactButton('-STEP', () => _changeSelectedNotePosition(track, note, note.startStep - nudgeStep), tooltip: 'Nudge Left'),
                      _buildCompactButton('+STEP', () => _changeSelectedNotePosition(track, note, note.startStep + nudgeStep), tooltip: 'Nudge Right'),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 24,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: EatsTheme.accentGold,
                    inactiveTrackColor: EatsTheme.controlBackground,
                    thumbColor: EatsTheme.accentGold,
                  ),
                  child: Slider(
                    value: note.startStep.clamp(0.0, maxPosStep),
                    min: 0.0,
                    max: math.max(0.1, maxPosStep),
                    onChanged: (val) => _changeSelectedNotePosition(track, note, val),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Row 4: Note Size / Duration Slider & Tap-Hold Manual Entry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: () => _openManualDurationDialog(context, track, note),
                    child: Tooltip(
                      message: 'Long-press for manual numeric input',
                      child: Row(
                        children: [
                          Text('SIZE: ', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(
                            '${note.durationSteps.toStringAsFixed(2)} st',
                            style: TextStyle(color: EatsTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text('(Hold for text input)', style: TextStyle(color: EatsTheme.textMuted.withOpacity(0.6), fontSize: 8)),
                ],
              ),
              SizedBox(
                height: 24,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: EatsTheme.primaryCyan,
                    inactiveTrackColor: EatsTheme.controlBackground,
                    thumbColor: EatsTheme.primaryCyan,
                  ),
                  child: Slider(
                    value: note.durationSteps.clamp(minDur, 16.0),
                    min: minDur,
                    max: 16.0,
                    onChanged: (val) => _changeSelectedNoteDuration(track, note, val),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Row 5: Velocity Slider & Tap-Hold Manual Entry (Plays audition sound on release!)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: () => _openManualVelocityDialog(context, track, note),
                    child: Tooltip(
                      message: 'Long-press for manual numeric input',
                      child: Row(
                        children: [
                          Text('VELOCITY: ', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(
                            '$velPercent%',
                            style: TextStyle(color: EatsTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text('(Hold for text input)', style: TextStyle(color: EatsTheme.textMuted.withOpacity(0.6), fontSize: 8)),
                ],
              ),
              SizedBox(
                height: 24,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: EatsTheme.primaryCyan,
                    inactiveTrackColor: EatsTheme.controlBackground,
                    thumbColor: EatsTheme.primaryCyan,
                  ),
                  child: Slider(
                    value: note.velocity.clamp(0.05, 1.0),
                    min: 0.05,
                    max: 1.0,
                    onChanged: (val) => _changeSelectedNoteVelocity(track, note, val),
                    onChangeEnd: (val) {
                      final clamped = val.clamp(0.05, 1.0);
                      widget.dawState.audioEngine.playNoteOrSample(
                        track: track,
                        midiNote: note.pitch,
                        velocity: clamped,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.dawState.activeTrack;
    final activeClip = widget.dawState.activeTrackClip;
    final activeClipSteps = (activeClip.barLength * 4.0).clamp(4.0, 64.0);
    final snap = widget.dawState.quantizeSnap;
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Find selected note object if it still exists
    Note? selectedNote;
    double? selectedNoteLeft;
    double? selectedNoteTop;
    double? selectedNoteWidth;
    double? selectedNoteHeight;

    if (_selectedNoteId != null) {
      final idx = track.notes.indexWhere((n) => n.id == _selectedNoteId);
      if (idx != -1) {
        selectedNote = track.notes[idx];
        final keyIdx = maxPitch - selectedNote.pitch;
        selectedNoteLeft = selectedNote.startStep * _stepWidth + 1;
        selectedNoteTop = keyIdx * _keyHeight + 1;
        selectedNoteWidth = ((selectedNote.durationSteps * _stepWidth) - 2).clamp(8.0, double.infinity);
        selectedNoteHeight = _keyHeight - 2;
      }
    }

    return Column(
      children: [
        // Sub-toolbar for Piano Roll (Note Stepper, Snap & Zoom Controls)
        Container(
          height: 32,
          color: EatsTheme.panelBackground,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Text(
                'PIANO ROLL',
                style: EatsTheme.getPrimaryFontStyle(
                  color: EatsTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),

              // Note Stepper Buttons
              Text('NOTES:', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 12),
                color: EatsTheme.primaryCyan,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Select Previous Note',
                onPressed: () => _selectPreviousNote(track),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 12),
                color: EatsTheme.primaryCyan,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Select Next Note',
                onPressed: () => _selectNextNote(track),
              ),
              IconButton(
                icon: const Icon(Icons.center_focus_strong, size: 14),
                color: EatsTheme.primaryCyan,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Center View vertically on Clip Notes (or C4)',
                onPressed: () => _centerViewOnNotesOrDefault(animate: true),
              ),
              const SizedBox(width: 8),

              // Clip Length Stepper
              Text('CLIP:', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 14),
                color: EatsTheme.accentGold,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                tooltip: 'Shorten Clip Loop Length',
                onPressed: () {
                  final activeClip = widget.dawState.activeTrackClip;
                  if (activeClip.barLength > 1) {
                    widget.dawState.setTrackClipBarLength(activeClip, activeClip.barLength - 1);
                  }
                },
              ),
              Text(
                '${widget.dawState.activeTrackClip.barLength} BAR${widget.dawState.activeTrackClip.barLength > 1 ? 'S' : ''}',
                style: TextStyle(color: EatsTheme.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 14),
                color: EatsTheme.accentGold,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                tooltip: 'Extend Clip Loop Length',
                onPressed: () {
                  final activeClip = widget.dawState.activeTrackClip;
                  if (activeClip.barLength < 16) {
                    widget.dawState.setTrackClipBarLength(activeClip, activeClip.barLength + 1);
                  }
                },
              ),
              const Spacer(),

              // Snap Quantize Dropdown
              Text('SNAP:', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              DropdownButton<double>(
                value: widget.dawState.quantizeSnap,
                dropdownColor: EatsTheme.panelBackground,
                underline: const SizedBox(),
                isDense: true,
                style: TextStyle(color: EatsTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text('1/32')),
                  DropdownMenuItem(value: 1.0, child: Text('1/16')),
                  DropdownMenuItem(value: 2.0, child: Text('1/8')),
                  DropdownMenuItem(value: 4.0, child: Text('1/4')),
                  DropdownMenuItem(value: 0.0, child: Text('Off')),
                ],
                onChanged: (val) {
                  if (val != null) widget.dawState.setQuantizeSnap(val);
                },
              ),
              const SizedBox(width: 8),

              // Zoom Controls
              Text('ZOOM:', style: TextStyle(color: EatsTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 15),
                color: EatsTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Zoom Out',
                onPressed: () => _zoom(0.8),
              ),
              IconButton(
                icon: const Icon(Icons.aspect_ratio, size: 13),
                color: EatsTheme.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Reset Zoom',
                onPressed: _resetZoom,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 15),
                color: EatsTheme.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
                // 2-Finger Pinch-to-Zoom
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
              }
            },
            child: Row(
              children: [
                // Virtual Piano Keyboard Column (Left - Synced SingleChildScrollView layout)
                SizedBox(
                  width: 70,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _keysScrollController,
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        height: totalKeys * _keyHeight,
                        child: Column(
                          children: List.generate(totalKeys, (idx) {
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
                                    bottom: BorderSide(
                                      color: isBlackKey ? Colors.black45 : Colors.grey.shade400,
                                      width: 1.0,
                                    ),
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
                          }),
                        ),
                      ),
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
                          _syncKeysScroll();
                          return false;
                        },
                        child: SingleChildScrollView(
                          controller: _gridScrollController,
                          scrollDirection: Axis.vertical,
                          child: GestureDetector(
                            onTap: () {
                              // Single tap on grid deselects active note and hides Note Properties dialog
                              if (_selectedNoteId != null) {
                                setState(() {
                                  _selectedNoteId = null;
                                });
                              }
                            },
                            onDoubleTapDown: (details) {
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
                                  final newNoteId = DateTime.now().millisecondsSinceEpoch.toString();
                                  final newNote = Note(
                                    id: newNoteId,
                                    pitch: pitch,
                                    startStep: snappedStep,
                                    durationSteps: duration,
                                    velocity: 0.85,
                                  );
                                  widget.dawState.addNote(track, newNote);
                                  setState(() {
                                    _selectedNoteId = newNoteId;
                                  });
                                  _ensureNoteAndMenuVisible(newNote);
                                }
                              }
                            },
                            child: Container(
                              height: totalKeys * _keyHeight,
                              color: EatsTheme.backgroundDark,
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
                                              ? (EatsTheme.isLight ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.02))
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: EatsTheme.isLight ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                                  // Vertical Bar/Step Grid Lines (Dimmed past active clip bounds)
                                  Row(
                                    children: List.generate(totalSteps, (stepIdx) {
                                      final isBarHeader = stepIdx % 4 == 0;
                                      final isPastClip = stepIdx >= activeClipSteps;

                                      return Container(
                                        width: _stepWidth,
                                        height: totalKeys * _keyHeight,
                                        decoration: BoxDecoration(
                                          color: isPastClip
                                              ? (EatsTheme.isLight ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.35))
                                              : Colors.transparent,
                                          border: Border(
                                            left: BorderSide(
                                              color: isBarHeader
                                                  ? (isPastClip
                                                      ? EatsTheme.textMuted.withOpacity(0.25)
                                                      : EatsTheme.primaryCyan.withOpacity(0.45))
                                                  : (EatsTheme.isLight ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.04)),
                                              width: isBarHeader ? 1.5 : 1.0,
                                            ),
                                            right: BorderSide(
                                              color: EatsTheme.isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.04),
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                              // Active Clip Loop End Line & Tag Badge
                              Positioned(
                                left: activeClipSteps * _stepWidth,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color: EatsTheme.accentGold.withOpacity(0.85),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        top: 4,
                                        left: -38,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: EatsTheme.accentGold,
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4),
                                            ],
                                          ),
                                          child: Text(
                                            'END OF CLIP',
                                            style: TextStyle(
                                              color: EatsTheme.backgroundDark,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Playhead Position Line
                              Positioned(
                                left: widget.dawState.currentStep * _stepWidth,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color: EatsTheme.primaryCyan,
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
                                final isSelected = note.id == _selectedNoteId;
                                final isPastClipLoop = note.startStep >= activeClipSteps;

                                final touchWidth = isMobile ? noteWidth.clamp(28.0, double.infinity) : noteWidth;
                                final touchHeight = isMobile ? noteHeight.clamp(28.0, double.infinity) : noteHeight;
                                final touchLeft = isMobile ? (noteLeft - (touchWidth - noteWidth) / 2).clamp(0.0, double.infinity) : noteLeft;
                                final touchTop = isMobile ? (noteTop - (touchHeight - noteHeight) / 2).clamp(0.0, double.infinity) : noteTop;

                                final rawVelocityColor = Color.lerp(
                                  const Color(0xFF0C0D12),
                                  track.color,
                                  (0.25 + 0.75 * note.velocity.clamp(0.05, 1.0)),
                                )!;
                                final effectiveNoteColor = isPastClipLoop
                                    ? rawVelocityColor.withOpacity(0.55)
                                    : rawVelocityColor;

                                return Positioned(
                                  left: touchLeft,
                                  top: touchTop,
                                  width: touchWidth,
                                  height: touchHeight,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (details) {
                                      setState(() {
                                        _selectedNoteId = note.id;
                                      });
                                      widget.dawState.audioEngine.playNoteOrSample(
                                        track: track,
                                        midiNote: note.pitch,
                                        velocity: note.velocity,
                                      );
                                      _ensureNoteAndMenuVisible(note);
                                    },
                                    onDoubleTap: () {
                                      widget.dawState.removeNote(track, note.id);
                                      if (_selectedNoteId == note.id) {
                                        setState(() => _selectedNoteId = null);
                                      }
                                    },
                                    onPanStart: (details) {
                                      _activeMoveNoteId = note.id;
                                      _moveStartStep = note.startStep;
                                      _moveStartPitch = note.pitch;
                                      _moveStartPos = details.globalPosition;
                                      setState(() => _selectedNoteId = note.id);
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
                                      if (_activeMoveNoteId == note.id) {
                                        _activeMoveNoteId = null;
                                        widget.dawState.audioEngine.playNoteOrSample(
                                          track: track,
                                          midiNote: note.pitch,
                                          velocity: note.velocity,
                                        );
                                        _ensureNoteAndMenuVisible(note);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: effectiveNoteColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: isSelected
                                            ? Border.all(color: EatsTheme.primaryCyan, width: 2.0)
                                            : (isPastClipLoop
                                                ? Border.all(color: EatsTheme.accentGold.withOpacity(0.5), width: 1.0)
                                                : Border.all(color: Colors.black45, width: 0.5)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected ? EatsTheme.primaryCyan.withOpacity(0.8) : effectiveNoteColor.withOpacity(0.4),
                                            blurRadius: isSelected ? 6 : 3,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getNoteName(note.pitch),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected
                                                ? EatsTheme.backgroundDark
                                                : (note.velocity < 0.45 ? Colors.white70 : EatsTheme.backgroundDark),
                                            fontSize: (_keyHeight * 0.38).clamp(8.0, 11.0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                  }),

                                  // Draw Dynamic "<>" Resize Handle directly after the selected note
                                  if (selectedNote != null &&
                                      selectedNoteLeft != null &&
                                      selectedNoteTop != null &&
                                      selectedNoteWidth != null &&
                                      selectedNoteHeight != null)
                                    Positioned(
                                      left: selectedNoteLeft + selectedNoteWidth + 1,
                                      top: selectedNoteTop,
                                      width: 22,
                                      height: selectedNoteHeight,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onPanStart: (details) {
                                          _activeResizeNoteId = selectedNote!.id;
                                          _resizeStartDuration = selectedNote.durationSteps;
                                          _resizeStartPos = details.globalPosition;
                                        },
                                        onPanUpdate: (details) {
                                          if (_activeResizeNoteId != selectedNote!.id ||
                                              _resizeStartDuration == null ||
                                              _resizeStartPos == null) return;

                                          final dxSteps = (details.globalPosition.dx - _resizeStartPos!.dx) / _stepWidth;
                                          final double minDur = snap > 0 ? snap : 0.25;
                                          double candidateDur = (_resizeStartDuration! + dxSteps).clamp(minDur, totalSteps - selectedNote.startStep);

                                          if (snap > 0) {
                                            candidateDur = (candidateDur / snap).round() * snap;
                                            if (candidateDur < snap) candidateDur = snap;
                                          }

                                          widget.dawState.updateNote(
                                            track,
                                            selectedNote.copyWith(durationSteps: candidateDur),
                                          );
                                        },
                                        onPanEnd: (_) {
                                          _activeResizeNoteId = null;
                                        },
                                        child: Tooltip(
                                          message: 'Drag to resize note',
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: EatsTheme.primaryCyan,
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(4),
                                                bottomRight: Radius.circular(4),
                                              ),
                                              boxShadow: [
                                                BoxShadow(color: EatsTheme.primaryCyan.withOpacity(0.6), blurRadius: 4),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '<>',
                                                style: TextStyle(
                                                  color: EatsTheme.isLight ? Colors.white : Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Floating FL Studio-style Hover Menu (inside grid Stack, zero layout bumping)
                                  if (selectedNote != null &&
                                      selectedNoteLeft != null &&
                                      selectedNoteTop != null &&
                                      selectedNoteWidth != null &&
                                      selectedNoteHeight != null)
                                    _buildSelectedNoteHoverCard(
                                      track,
                                      selectedNote,
                                      snap,
                                      selectedNoteLeft,
                                      selectedNoteTop,
                                      selectedNoteWidth,
                                      selectedNoteHeight,
                                    ),
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

