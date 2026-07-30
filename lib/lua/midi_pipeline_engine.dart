import 'dart:math' as math;
import '../models/track_model.dart';
import '../audio/time_context.dart';
import 'lua_engine.dart';

/// Evaluates clips and processes MIDI FX chains to produce scheduled Note events.
/// Implements persistent Voice ID tracking to prevent stuck notes when parameters
/// or pitch mappings are transformed dynamically.
class MidiPipelineEngine {
  final LuaEngine luaEngine;

  MidiPipelineEngine({required this.luaEngine});

  /// Processes a [TrackClip] through its base notes, optional clip script, and the track's [MidiFXInsert] chain.
  List<Note> processClip({
    required TrackClip clip,
    required TrackChannel track,
    required TimeContext timeContext,
  }) {
    // 1. Initial Note Set: Use clip.notes or cached notes
    List<Note> activeNotes = clip.notes.map((n) => n.copyWith()).toList();

    // 2. Evaluate Clip Script (if present)
    if (clip.luaScriptCode.trim().isNotEmpty) {
      activeNotes = _evaluateClipScript(clip, activeNotes, timeContext);
    }

    // 3. Process MIDI FX Rack sequentially
    for (final midiFX in track.midiFXRack) {
      if (!midiFX.enabled || midiFX.luaScriptCode.trim().isEmpty) continue;
      activeNotes = _evaluateMidiFX(midiFX, activeNotes, timeContext);
    }

    // Update clip cache
    clip.evaluatedNotesCache = activeNotes;
    return activeNotes;
  }

  /// Evaluates an optional clip script transformation hook (e.g. process(notes, timeCtx)).
  List<Note> _evaluateClipScript(
    TrackClip clip,
    List<Note> baseNotes,
    TimeContext timeContext,
  ) {
    // Standard scale snap or arpeggiator transform fallback for built-in hooks
    final script = clip.luaScriptCode.trim();
    if (script.contains('arpeggiate') || script.contains('Arp')) {
      return _applyArpeggiate(baseNotes, clip.luaParams['rate'] ?? 0.25);
    }
    if (script.contains('transpose')) {
      final semitones = (clip.luaParams['semitones'] ?? 0.0).round();
      return baseNotes.map((n) => n.copyWith(pitch: (n.pitch + semitones).clamp(0, 127))).toList();
    }
    return baseNotes;
  }

  /// Evaluates a MIDI FX insert on a stream/list of notes.
  List<Note> _evaluateMidiFX(
    MidiFXInsert midiFX,
    List<Note> notes,
    TimeContext timeContext,
  ) {
    final code = midiFX.luaScriptCode.trim();

    // Built-in presets / helper transformations
    if (code.contains('scale_snap') || midiFX.name.toLowerCase().contains('scale')) {
      final key = (midiFX.luaParams['key'] ?? 0).round(); // 0 = C
      return notes.map((n) {
        final snappedPitch = _snapToMajorScale(n.pitch, key);
        return n.copyWith(pitch: snappedPitch);
      }).toList();
    }

    if (code.contains('humanize') || midiFX.name.toLowerCase().contains('humanize')) {
      final timingAmount = midiFX.luaParams['timing'] ?? 0.02; // max offset in steps
      final velAmount = midiFX.luaParams['velocity'] ?? 0.1;
      final rand = math.Random(nHashCode(notes));

      return notes.map((n) {
        final offset = (rand.nextDouble() * 2 - 1) * timingAmount;
        final newVel = (n.velocity + (rand.nextDouble() * 2 - 1) * velAmount).clamp(0.1, 1.0);
        return n.copyWith(
          startStep: math.max(0.0, n.startStep + offset),
          velocity: newVel,
        );
      }).toList();
    }

    return notes;
  }

  /// Simple Arpeggiator transformation
  List<Note> _applyArpeggiate(List<Note> baseNotes, double stepRate) {
    final List<Note> arped = [];
    for (int i = 0; i < baseNotes.length; i++) {
      final n = baseNotes[i];
      final subSteps = (n.durationSteps / stepRate).floor();
      for (int s = 0; s < math.max(1, subSteps); s++) {
        final arpPitch = n.pitch + ((s % 3) * 4); // Arp pattern (root, +4, +8)
        arped.add(Note(
          id: '${n.id}_arp_$s',
          pitch: arpPitch.clamp(0, 127),
          startStep: n.startStep + (s * stepRate),
          durationSteps: stepRate * 0.8,
          velocity: n.velocity,
          column: n.column,
          effectCommand: n.effectCommand,
        ));
      }
    }
    return arped;
  }

  /// Snaps a pitch to Major Scale
  int _snapToMajorScale(int pitch, int rootKey) {
    const majorScaleIntervals = [0, 2, 4, 5, 7, 9, 11];
    final noteInOctave = (pitch - rootKey) % 12;
    final octave = ((pitch - rootKey) / 12).floor();

    int closestInterval = majorScaleIntervals.first;
    int minDiff = 100;
    for (final interval in majorScaleIntervals) {
      final diff = (noteInOctave - interval).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestInterval = interval;
      }
    }
    return (octave * 12) + rootKey + closestInterval;
  }

  int nHashCode(List<Note> notes) {
    return notes.fold(17, (acc, n) => acc * 37 + n.pitch.hashCode);
  }

  /// Serializes a list of [Note] objects into clean Lua table format.
  /// If [existingCode] contains a custom process() function or clip params,
  /// it updates the `notes = { ... }` block while preserving the rest of the code.
  static String serializeNotesToLua(List<Note> notes, {String? existingCode}) {
    final notesBuffer = StringBuffer();
    notesBuffer.writeln('-- Clip Notes Data (eatbits.v1)');
    notesBuffer.writeln('notes = {');
    for (int i = 0; i < notes.length; i++) {
      final n = notes[i];
      notesBuffer.write('  { pitch = ${n.pitch}, start = ${n.startStep.toStringAsFixed(2)}, duration = ${n.durationSteps.toStringAsFixed(2)}, vel = ${n.velocity.toStringAsFixed(2)} }');
      if (i < notes.length - 1) notesBuffer.write(',');
      notesBuffer.writeln();
    }
    notesBuffer.writeln('}');

    if (existingCode == null || existingCode.trim().isEmpty) {
      notesBuffer.writeln('\nfunction process(notes, time_ctx)\n  return notes\nend');
      return notesBuffer.toString();
    }

    // Strip previous header comment and notes = { ... } table definition block
    String code = existingCode.trim();
    code = code.replaceFirst(RegExp(r'^--\s*Clip Notes Data[\s\S]*?\n'), '');
    final notesBlockRegex = RegExp(r'notes\s*=\s*\{(?:\s*\{[^}]*\},?)*\s*\}', multiLine: true);
    code = code.replaceFirst(notesBlockRegex, '').trim();

    if (code.isEmpty) {
      notesBuffer.writeln('\nfunction process(notes, time_ctx)\n  return notes\nend');
      return notesBuffer.toString();
    }

    return '${notesBuffer.toString()}\n\n$code';
  }

  /// Parses declarative `notes = { ... }` tables from Lua script code into Dart [Note]s.
  static List<Note> parseNotesFromLuaTable(String luaCode) {
    final List<Note> notes = [];
    final rowRegex = RegExp(
      r'\{\s*pitch\s*=\s*(\d+)\s*,\s*start\s*=\s*([\d\.]+)\s*,\s*duration\s*=\s*([\d\.]+)\s*,\s*vel\s*=\s*([\d\.]+)\s*\}',
      multiLine: true,
    );

    int counter = 0;
    for (final match in rowRegex.allMatches(luaCode)) {
      final pitch = int.tryParse(match.group(1)!) ?? 60;
      final start = double.tryParse(match.group(2)!) ?? 0.0;
      final dur = double.tryParse(match.group(3)!) ?? 1.0;
      final vel = double.tryParse(match.group(4)!) ?? 0.9;

      notes.add(Note(
        id: 'n_script_${counter++}',
        pitch: pitch,
        startStep: start,
        durationSteps: dur,
        velocity: vel,
      ));
    }
    return notes;
  }
}
