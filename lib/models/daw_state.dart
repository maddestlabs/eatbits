import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../audio/audio_engine.dart';
import '../audio/wav_exporter.dart';
import '../theme/daw_theme.dart';
import '../wren/wren_engine.dart';
import '../wren/wren_preset_library.dart';
import 'track_model.dart';

class DawState extends ChangeNotifier {
  final AudioEngine audioEngine = AudioEngine();

  // Navigation & View Mode
  int _activeTabIndex = 0; // 0: Sequencer, 1: Piano Roll, 2: Mixer, 3: Wren Workbench, 4: Arranger
  int get activeTabIndex => _activeTabIndex;
  set activeTabIndex(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  void setThemePreset(DawThemePreset preset) {
    DawTheme.currentPreset = preset;
    notifyListeners();
  }

  // Playback & Clock State
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isSongMode = false;
  bool get isSongMode => _isSongMode;
  set isSongMode(bool val) {
    _isSongMode = val;
    notifyListeners();
  }

  double _bpm = 124.0;
  double get bpm => _bpm;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  int _currentBar = 0;
  int get currentBar => _currentBar;

  double _masterVolume = 0.85;
  double get masterVolume => _masterVolume;

  Timer? _playbackTimer;

  // Tap Tempo state
  final List<DateTime> _tapTimes = [];

  // Patterns & Tracks
  late List<Pattern> patterns;
  int _activePatternIndex = 0;
  int get activePatternIndex => _activePatternIndex;

  Pattern get activePattern => patterns[_activePatternIndex];

  int _activeTrackIndex = 0;
  int get activeTrackIndex => _activeTrackIndex;
  TrackChannel get activeTrack => activePattern.tracks[_activeTrackIndex];

  set activeTrackIndex(int index) {
    _activeTrackIndex = index.clamp(0, activePattern.tracks.length - 1);
    notifyListeners();
  }

  // Song Arrangement
  List<ArrangementItem> arrangement = [
    ArrangementItem(patternId: 'p0', startBar: 0, barLength: 4),
    ArrangementItem(patternId: 'p1', startBar: 4, barLength: 4),
  ];

  // Wren Editor Active Code & Logs
  String wrenCode = WrenPresetLibrary.presets.first.code;
  WrenCompilationResult compilationResult = WrenEngine.compile(WrenPresetLibrary.presets.first.code);

  DawState() {
    _initDemoTracks();
    _startMeterTimer();
  }

  void _startMeterTimer() {
    Timer.periodic(const Duration(milliseconds: 50), (_) {
      audioEngine.updateMeters();
      notifyListeners();
    });
  }

  void _initDemoTracks() {
    final trackKick = TrackChannel(
      id: 't_kick',
      name: 'Kick Drum',
      color: DawTheme.secondaryMagenta,
      type: TrackType.sampler,
      sampleName: 'kick',
      volume: 0.95,
      steps: List.generate(32, (i) => StepEvent(active: i % 4 == 0, velocity: 0.95)),
    );

    final trackSnare = TrackChannel(
      id: 't_snare',
      name: 'Snare (Wren DSP)',
      color: DawTheme.primaryCyan,
      type: TrackType.wrenScript,
      wrenScriptCode: WrenPresetLibrary.presets[1].code, // Procedural Snare
      wrenParams: {'ToneFreq': 185.0, 'Snappy': 0.65, 'Decay': 0.22},
      volume: 0.85,
      steps: List.generate(32, (i) => StepEvent(active: i % 8 == 4, velocity: 0.9)),
    );

    final trackHat = TrackChannel(
      id: 't_hihat',
      name: 'Hi-Hat (Wren DSP)',
      color: DawTheme.accentGold,
      type: TrackType.wrenScript,
      wrenScriptCode: WrenPresetLibrary.presets[2].code, // Procedural Hi-Hat
      wrenParams: {'Cutoff': 8500.0, 'Decay': 0.09, 'Metallic': 0.4},
      volume: 0.75,
      steps: List.generate(32, (i) => StepEvent(active: i % 2 == 0, velocity: i % 4 == 2 ? 0.9 : 0.6)),
    );

    final trackClap = TrackChannel(
      id: 't_clap',
      name: 'Clap (Wren DSP)',
      color: DawTheme.accentOrange,
      type: TrackType.wrenScript,
      wrenScriptCode: WrenPresetLibrary.presets[3].code, // Procedural Clap
      wrenParams: {'RoomDecay': 0.18, 'Tone': 2200.0},
      volume: 0.8,
      steps: List.generate(32, (i) => StepEvent(active: i == 12 || i == 28, velocity: 0.85)),
    );

    // Wren Script Track - JC-303 Acid Synth
    final trackWren303 = TrackChannel(
      id: 't_wren_303',
      name: 'JC-303 Acid Synth',
      color: DawTheme.accentGreen,
      type: TrackType.wrenScript,
      volume: 0.9,
      wrenScriptCode: WrenPresetLibrary.presets[0].code, // JC-303 Acid Bass
      wrenParams: {
        'Waveform': 0.0,
        'Cutoff': 1800.0,
        'Resonance': 8.0,
        'EnvMod': 0.75,
        'Decay': 0.28,
        'Accent': 0.6,
        'Slide': 0.4,
        'Overdrive': 0.3,
      },
      notes: [
        Note(id: 'n1', pitch: 36, startStep: 0, durationSteps: 2, velocity: 0.9), // C2
        Note(id: 'n2', pitch: 36, startStep: 2, durationSteps: 1, velocity: 0.8),
        Note(id: 'n3', pitch: 48, startStep: 3, durationSteps: 1, velocity: 1.0), // C3
        Note(id: 'n4', pitch: 39, startStep: 4, durationSteps: 2, velocity: 0.85), // D#2
        Note(id: 'n5', pitch: 41, startStep: 6, durationSteps: 2, velocity: 0.9), // F2
        Note(id: 'n6', pitch: 43, startStep: 8, durationSteps: 2, velocity: 0.9), // G2
        Note(id: 'n7', pitch: 36, startStep: 10, durationSteps: 2, velocity: 0.95),
        Note(id: 'n8', pitch: 48, startStep: 12, durationSteps: 2, velocity: 1.0),
        Note(id: 'n9', pitch: 46, startStep: 14, durationSteps: 2, velocity: 0.9),
      ],
      steps: List.generate(32, (i) => StepEvent(active: i % 2 == 0, velocity: 0.85, pitch: 36 + (i * 3) % 12)),
    );

    // Standard PolySynth Track
    final trackPolySynth = TrackChannel(
      id: 't_polysynth',
      name: 'Poly Lead Synth',
      color: DawTheme.accentPurple,
      type: TrackType.synth,
      synthWaveform: 'sawtooth',
      cutoff: 4000.0,
      volume: 0.8,
      notes: [
        Note(id: 'pn1', pitch: 60, startStep: 0, durationSteps: 4, velocity: 0.9), // C4
        Note(id: 'pn2', pitch: 64, startStep: 4, durationSteps: 4, velocity: 0.85), // E4
        Note(id: 'pn3', pitch: 67, startStep: 8, durationSteps: 4, velocity: 0.9), // G4
        Note(id: 'pn4', pitch: 72, startStep: 12, durationSteps: 4, velocity: 0.95), // C5
      ],
    );

    trackKick.clips.add(TrackClip(id: 'c_k1', name: 'Kick Beat A', trackId: trackKick.id, startBar: 0, barLength: 4));
    trackSnare.clips.add(TrackClip(id: 'c_s1', name: 'Snare Pattern', trackId: trackSnare.id, startBar: 0, barLength: 4));
    trackHat.clips.add(TrackClip(id: 'c_h1', name: 'Hi-Hat Groove', trackId: trackHat.id, startBar: 0, barLength: 4));
    trackClap.clips.add(TrackClip(id: 'c_c1', name: 'Clap Fill', trackId: trackClap.id, startBar: 2, barLength: 2));
    trackWren303.clips.add(TrackClip(id: 'c_w1', name: 'Acid 303 Riff', trackId: trackWren303.id, startBar: 0, barLength: 4, notes: trackWren303.notes));
    trackPolySynth.clips.add(TrackClip(id: 'c_p1', name: 'Lead Chord', trackId: trackPolySynth.id, startBar: 0, barLength: 4, notes: trackPolySynth.notes));

    patterns = [
      Pattern(
        id: 'p0',
        name: 'Pattern A',
        lengthSteps: 16,
        tracks: [trackKick, trackSnare, trackHat, trackClap, trackWren303, trackPolySynth],
      ),
      Pattern(
        id: 'p1',
        name: 'Pattern B',
        lengthSteps: 32,
        tracks: [
          trackKick.copyWith(id: 'p1_k'),
          trackSnare.copyWith(id: 'p1_s'),
          trackHat.copyWith(id: 'p1_h'),
          trackClap.copyWith(id: 'p1_c'),
          trackWren303.copyWith(id: 'p1_w'),
          trackPolySynth.copyWith(id: 'p1_p'),
        ],
      ),
    ];
  }

  TrackClip? activeClip;

  void openClipInEditor(TrackClip clip) {
    activeClip = clip;
    final tIdx = activePattern.tracks.indexWhere((t) => t.id == clip.trackId);
    if (tIdx != -1) {
      _activeTrackIndex = tIdx;
    }
    _activeTabIndex = 1; // Switch to EDIT tab
    notifyListeners();
  }

  void addClipToTrack(TrackChannel track, int startBar) {
    final newClip = TrackClip(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: '${track.name} Clip',
      trackId: track.id,
      startBar: startBar,
      barLength: 4,
    );
    track.clips.add(newClip);
    activeClip = newClip;
    notifyListeners();
  }

  void selectClip(TrackClip clip) {
    activeClip = clip;
    notifyListeners();
  }

  void selectPattern(int index) {
    _activePatternIndex = index.clamp(0, patterns.length - 1);
    notifyListeners();
  }

  void setBpm(double newBpm) {
    _bpm = newBpm.clamp(40.0, 240.0);
    if (_isPlaying) {
      _restartTimer();
    }
    notifyListeners();
  }

  void tapTempo() {
    final now = DateTime.now();
    _tapTimes.add(now);
    if (_tapTimes.length > 4) _tapTimes.removeAt(0);

    if (_tapTimes.length >= 2) {
      double totalDiffMs = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalDiffMs += _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      }
      final avgDiffMs = totalDiffMs / (_tapTimes.length - 1);
      if (avgDiffMs > 0) {
        setBpm(60000.0 / avgDiffMs);
      }
    }
  }

  void setMasterVolume(double vol) {
    _masterVolume = vol.clamp(0.0, 1.5);
    audioEngine.setMasterVolume(_masterVolume);
    notifyListeners();
  }

  double _nextNoteTime = 0.0;
  static const double _scheduleAheadTime = 0.120; // 120ms hardware look-ahead window

  void togglePlay() {
    audioEngine.ensureContextRunning();
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _currentStep = 0;
      _nextNoteTime = audioEngine.currentTime + 0.02;
      _startSchedulerTimer();
    } else {
      _playbackTimer?.cancel();
    }
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _currentStep = 0;
    notifyListeners();
  }

  void _startSchedulerTimer() {
    _playbackTimer?.cancel();
    // High frequency 25ms ticker enqueueing notes into WebAudio hardware clock queue
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      _schedulerLoop();
    });
  }

  void _restartTimer() {
    if (_isPlaying) _startSchedulerTimer();
  }

  void _schedulerLoop() {
    if (!_isPlaying) return;

    final currentPattern = activePattern;
    final int patternLength = currentPattern.lengthSteps;
    final double stepDurationSec = 60.0 / _bpm / 4.0; // 16th note step length in seconds

    while (_nextNoteTime < audioEngine.currentTime + _scheduleAheadTime) {
      _scheduleStep(_currentStep, _nextNoteTime, stepDurationSec);
      _nextNoteTime += stepDurationSec;
      _currentStep = (_currentStep + 1) % patternLength;
      if (_currentStep == 0) {
        _currentBar = (_currentBar + 1) % 100;
      }
    }
    notifyListeners();
  }

  void _scheduleStep(int stepIdx, double hardwareTime, double stepDurationSec) {
    final currentPattern = activePattern;
    final hasSolo = currentPattern.tracks.any((t) => t.isSoloed);

    for (final track in currentPattern.tracks) {
      if (track.isMuted) continue;
      if (hasSolo && !track.isSoloed) continue;

      // 1. Step Sequencer Events
      if (stepIdx < track.steps.length) {
        final step = track.steps[stepIdx];
        if (step.active) {
          audioEngine.playNoteOrSample(
            track: track,
            midiNote: step.pitch,
            velocity: step.velocity,
            scheduledTime: hardwareTime,
          );
        }
      }

      // 2. Piano Roll Note Events
      for (final note in track.notes) {
        if (note.startStep.toInt() == stepIdx) {
          audioEngine.playNoteOrSample(
            track: track,
            midiNote: note.pitch,
            velocity: note.velocity,
            durationSec: (note.durationSteps * stepDurationSec),
            scheduledTime: hardwareTime,
          );
        }
      }
    }
  }

  // Step Editing
  void toggleStep(TrackChannel track, int stepIndex) {
    if (stepIndex >= 0 && stepIndex < track.steps.length) {
      track.steps[stepIndex].active = !track.steps[stepIndex].active;
      if (track.steps[stepIndex].active) {
        audioEngine.playNoteOrSample(
          track: track,
          midiNote: track.steps[stepIndex].pitch,
          velocity: track.steps[stepIndex].velocity,
        );
      }
      notifyListeners();
    }
  }

  void setStepVelocity(TrackChannel track, int stepIndex, double velocity) {
    if (stepIndex >= 0 && stepIndex < track.steps.length) {
      track.steps[stepIndex].velocity = velocity.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  // Piano Roll Note Editing
  void addNote(TrackChannel track, Note note) {
    track.notes.add(note);
    audioEngine.playNoteOrSample(
      track: track,
      midiNote: note.pitch,
      velocity: note.velocity,
    );
    notifyListeners();
  }

  void removeNote(TrackChannel track, String noteId) {
    track.notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
  }

  // Mixer Editing
  void setTrackVolume(TrackChannel track, double volume) {
    track.volume = volume.clamp(0.0, 1.5);
    notifyListeners();
  }

  void setTrackPan(TrackChannel track, double pan) {
    track.pan = pan.clamp(-1.0, 1.0);
    notifyListeners();
  }

  void toggleMute(TrackChannel track) {
    track.isMuted = !track.isMuted;
    notifyListeners();
  }

  void toggleSolo(TrackChannel track) {
    track.isSoloed = !track.isSoloed;
    notifyListeners();
  }

  // Wren Engine Compilation & Hot Swap
  void compileWrenCode(String code) {
    wrenCode = code;
    compilationResult = WrenEngine.compile(code);

    if (compilationResult.isSuccess) {
      // Synchronize Wren parameters to active track
      activeTrack.wrenScriptCode = code;
      for (final p in compilationResult.params) {
        activeTrack.wrenParams[p.name] ??= p.defaultValue;
      }
    }
    notifyListeners();
  }

  void loadWrenPreset(WrenPreset preset) {
    wrenCode = preset.code;
    compileWrenCode(preset.code);
  }

  void updateWrenParam(String paramName, double value) {
    activeTrack.wrenParams[paramName] = value;
    notifyListeners();
  }

  void setPatternLength(Pattern pattern, int length) {
    pattern.lengthSteps = length;
    notifyListeners();
  }

  void removeArrangementItem(int index) {
    if (index >= 0 && index < arrangement.length) {
      arrangement.removeAt(index);
      notifyListeners();
    }
  }

  void toggleBitcrusher(TrackChannel track, bool enable) {
    if (enable) {
      track.fxRack.add(FXInsert(
        id: 'fx_bc',
        name: 'Bitcrusher',
        type: FXType.bitcrusher,
        params: {'Bits': 6.0, 'Downsample': 4.0, 'Mix': 0.8},
      ));
    } else {
      track.fxRack.removeWhere((f) => f.name == 'Bitcrusher');
    }
    notifyListeners();
  }

  void setTrackActiveView(TrackChannel track, MusicViewType viewType) {
    track.activeView = viewType;
    notifyListeners();
  }

  void setTrackerColumns(TrackChannel track, int columns) {
    track.trackerColumns = columns.clamp(1, 8);
    notifyListeners();
  }

  void toggleDistortion(TrackChannel track, bool enable) {
    if (enable) {
      track.fxRack.add(FXInsert(
        id: 'fx_td',
        name: 'TubeDistortion',
        type: FXType.distortion,
        params: {'Drive': 6.0, 'OutGain': 0.7},
      ));
    } else {
      track.fxRack.removeWhere((f) => f.name == 'TubeDistortion');
    }
    notifyListeners();
  }

  // WAV Song Export
  void exportWavSong() {
    final int totalSamples = (44100 * (60.0 / _bpm) * 16).toInt();
    final leftBuffer = List<double>.filled(totalSamples, 0.0);
    final rightBuffer = List<double>.filled(totalSamples, 0.0);

    // Simple audio render pass
    for (int i = 0; i < totalSamples; i++) {
      final t = i / 44100.0;
      final osc = math.sin(2.0 * math.pi * 120.0 * t) * math.exp(-t * 2.0);
      leftBuffer[i] = osc * 0.7;
      rightBuffer[i] = osc * 0.7;
    }

    final wavBytes = WavExporter.encodeWav(
      leftSamples: leftBuffer,
      rightSamples: rightBuffer,
    );

    WavExporter.saveWavFile(wavBytes, 'wren_daw_song.wav');
  }
}
