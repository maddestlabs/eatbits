import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../audio/audio_engine.dart';
import '../audio/wav_exporter.dart';
import '../theme/daw_theme.dart';
import '../lua/lua_engine.dart';
import '../lua/lua_preset_library.dart';
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
    final newIndex = index.clamp(0, activePattern.tracks.length - 1);
    if (_activeTrackIndex != newIndex || luaCode.isEmpty) {
      _activeTrackIndex = newIndex;
      if (activeTrack.luaScriptCode.isNotEmpty) {
        luaCode = activeTrack.luaScriptCode;
        compilationResult = LuaEngine.compile(luaCode);
      }
    }
    notifyListeners();
  }

  // Song Arrangement
  List<ArrangementItem> arrangement = [
    ArrangementItem(patternId: 'p0', startBar: 0, barLength: 4),
    ArrangementItem(patternId: 'p1', startBar: 4, barLength: 4),
  ];

  // Lua Editor Active Code & Logs
  String luaCode = LuaPresetLibrary.presets.first.code;
  LuaCompilationResult compilationResult = LuaEngine.compile(LuaPresetLibrary.presets.first.code);

  // Backward compatibility getters
  String get wrenCode => luaCode;
  set wrenCode(String val) => luaCode = val;

  DawState() {
    _initDemoTracks();
    _startMeterTimer();
  }

  void _startMeterTimer() {
    Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isPlaying) {
        audioEngine.updateMeters();
      }
    });
  }

  void _initDemoTracks() {
    final trackKick = TrackChannel(
      id: 't_kick',
      name: 'Kick Drum (Lua DSP)',
      color: DawTheme.secondaryMagenta,
      type: TrackType.luaScript,
      luaScriptCode: LuaPresetLibrary.presets[1].code, // Procedural Kick
      luaParams: {'StartFreq': 160.0, 'EndFreq': 42.0, 'PitchDecay': 0.035, 'AmpDecay': 0.35, 'Click': 0.5},
      volume: 0.95,
      steps: List.generate(32, (i) => StepEvent(active: i % 4 == 0, velocity: 0.95, pitch: 36)),
      notes: List.generate(32, (i) => i % 4 == 0 ? Note(id: 'k_$i', pitch: 36, startStep: i.toDouble(), durationSteps: 1.0, velocity: 0.95) : null)
          .whereType<Note>()
          .toList(),
    );

    final trackSnare = TrackChannel(
      id: 't_snare',
      name: 'Snare (Lua DSP)',
      color: DawTheme.primaryCyan,
      type: TrackType.luaScript,
      luaScriptCode: LuaPresetLibrary.presets[2].code, // Procedural Snare
      luaParams: {'ToneFreq': 185.0, 'Snappy': 0.65, 'Decay': 0.22},
      volume: 0.85,
      steps: List.generate(32, (i) => StepEvent(active: i % 8 == 4, velocity: 0.9, pitch: 38)),
      notes: List.generate(32, (i) => i % 8 == 4 ? Note(id: 's_$i', pitch: 38, startStep: i.toDouble(), durationSteps: 1.0, velocity: 0.9) : null)
          .whereType<Note>()
          .toList(),
    );

    final trackHat = TrackChannel(
      id: 't_hihat',
      name: 'Hi-Hat (Lua DSP)',
      color: DawTheme.accentGold,
      type: TrackType.luaScript,
      luaScriptCode: LuaPresetLibrary.presets[3].code, // Procedural Hi-Hat
      luaParams: {'Cutoff': 8500.0, 'Decay': 0.09, 'Metallic': 0.4},
      volume: 0.75,
      steps: List.generate(32, (i) => StepEvent(active: i % 2 == 0, velocity: i % 4 == 2 ? 0.9 : 0.6, pitch: 42)),
      notes: List.generate(32, (i) => i % 2 == 0 ? Note(id: 'h_$i', pitch: 42, startStep: i.toDouble(), durationSteps: 1.0, velocity: i % 4 == 2 ? 0.9 : 0.6) : null)
          .whereType<Note>()
          .toList(),
    );

    final trackClap = TrackChannel(
      id: 't_clap',
      name: 'Clap (Lua DSP)',
      color: DawTheme.accentOrange,
      type: TrackType.luaScript,
      luaScriptCode: LuaPresetLibrary.presets[4].code, // Procedural Clap
      luaParams: {'RoomDecay': 0.18, 'Tone': 2200.0},
      volume: 0.8,
      steps: List.generate(32, (i) => StepEvent(active: i == 12 || i == 28, velocity: 0.85, pitch: 39)),
      notes: List.generate(32, (i) => (i == 12 || i == 28) ? Note(id: 'c_$i', pitch: 39, startStep: i.toDouble(), durationSteps: 1.0, velocity: 0.85) : null)
          .whereType<Note>()
          .toList(),
    );

    // Lua Script Track - JC-303 Acid Synth
    final trackLua303 = TrackChannel(
      id: 't_lua_303',
      name: 'JC-303 Acid Synth',
      color: DawTheme.accentGreen,
      type: TrackType.luaScript,
      volume: 0.9,
      luaScriptCode: LuaPresetLibrary.presets[0].code, // JC-303 Acid Bass
      luaParams: {
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

    // Poly Lead Synth Track (Lua DSP)
    final trackPolySynth = TrackChannel(
      id: 't_polysynth',
      name: 'Poly Lead (Lua DSP)',
      color: DawTheme.accentPurple,
      type: TrackType.luaScript,
      luaScriptCode: LuaPresetLibrary.presets[5].code, // Poly Lead Synth
      luaParams: {'Cutoff': 4500.0, 'Resonance': 3.0, 'Detune': 3.0, 'Attack': 0.01, 'Release': 0.35},
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

    trackKick.clips.add(TrackClip(id: 'c_k1', name: 'Kick Beat A', trackId: trackKick.id, startBar: 0, barLength: 4, notes: trackKick.notes));
    trackSnare.clips.add(TrackClip(id: 'c_s1', name: 'Snare Pattern', trackId: trackSnare.id, startBar: 0, barLength: 4, notes: trackSnare.notes));
    trackHat.clips.add(TrackClip(id: 'c_h1', name: 'Hi-Hat Groove', trackId: trackHat.id, startBar: 0, barLength: 4, notes: trackHat.notes));
    trackClap.clips.add(TrackClip(id: 'c_c1', name: 'Clap Fill', trackId: trackClap.id, startBar: 2, barLength: 2, notes: trackClap.notes));
    trackLua303.clips.add(TrackClip(id: 'c_w1', name: 'Acid 303 Riff', trackId: trackLua303.id, startBar: 0, barLength: 4, notes: trackLua303.notes));
    trackPolySynth.clips.add(TrackClip(id: 'c_p1', name: 'Lead Chord', trackId: trackPolySynth.id, startBar: 0, barLength: 4, notes: trackPolySynth.notes));

    patterns = [
      Pattern(
        id: 'p0',
        name: 'Pattern A',
        lengthSteps: 16,
        tracks: [trackKick, trackSnare, trackHat, trackClap, trackLua303, trackPolySynth],
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
          trackLua303.copyWith(id: 'p1_w'),
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

  // Loop Points & Arranger Seek State
  int _loopStartBar = 0;
  int get loopStartBar => _loopStartBar;

  int _loopEndBar = 8;
  int get loopEndBar => _loopEndBar;

  bool _isLooping = true;
  bool get isLooping => _isLooping;

  int _arrangerStep = 0;
  int get arrangerStep => _arrangerStep;

  void setLoopPoints(int startBar, int endBar) {
    _loopStartBar = math.max(0, math.min(startBar, endBar - 1));
    _loopEndBar = math.max(_loopStartBar + 1, endBar);
    notifyListeners();
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void seekToBar(int bar) {
    final targetBar = bar.clamp(0, 31);
    _currentStep = targetBar * 16;
    _arrangerStep = targetBar * 16;
    _currentBar = targetBar;
    notifyListeners();
  }

  double _nextNoteTime = 0.0;
  static const double _scheduleAheadTime = 0.120; // 120ms hardware look-ahead window

  void togglePlay() {
    audioEngine.ensureContextRunning();
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
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
    _currentStep = _isLooping ? _loopStartBar * 16 : 0;
    _arrangerStep = _currentStep;
    _currentBar = _currentStep ~/ 16;
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

    final double stepDurationSec = 60.0 / _bpm / 4.0; // 16th note step length in seconds
    final bool inArranger = (_activeTabIndex == 4 || _isSongMode);
    final int maxSteps = inArranger ? 32 * 16 : activePattern.lengthSteps;

    while (_nextNoteTime < audioEngine.currentTime + _scheduleAheadTime) {
      _scheduleStep(_currentStep, _nextNoteTime, stepDurationSec);
      _nextNoteTime += stepDurationSec;

      _currentStep++;
      if (inArranger && _isLooping && _currentStep >= _loopEndBar * 16) {
        _currentStep = _loopStartBar * 16;
      } else if (_currentStep >= maxSteps) {
        _currentStep = inArranger && _isLooping ? _loopStartBar * 16 : 0;
      }

      _arrangerStep = _currentStep;
      _currentBar = _currentStep ~/ 16;
    }
    notifyListeners();
  }

  void _scheduleStep(int stepIdx, double hardwareTime, double stepDurationSec) {
    final currentPattern = activePattern;
    final hasSolo = currentPattern.tracks.any((t) => t.isSoloed);
    final bool isArrangerPlayback = (_activeTabIndex == 4 || _isSongMode);

    for (final track in currentPattern.tracks) {
      if (track.isMuted) continue;
      if (hasSolo && !track.isSoloed) continue;

      if (isArrangerPlayback) {
        // Arranger Clip Position Playback Logic
        for (final clip in track.clips) {
          final int clipStartStep = clip.startBar * 16;
          final int clipEndStep = (clip.startBar + clip.barLength) * 16;

          if (stepIdx >= clipStartStep && stepIdx < clipEndStep) {
            final int localStep = stepIdx - clipStartStep;
            
            if (clip.notes.isNotEmpty) {
              for (final note in clip.notes) {
                if (note.startStep.toInt() == localStep) {
                  audioEngine.playNoteOrSample(
                    track: track,
                    midiNote: note.pitch,
                    velocity: note.velocity,
                    durationSec: note.durationSteps * stepDurationSec,
                    scheduledTime: hardwareTime,
                  );
                }
              }
            } else if (localStep < track.steps.length) {
              final step = track.steps[localStep % track.steps.length];
              if (step.active) {
                audioEngine.playNoteOrSample(
                  track: track,
                  midiNote: step.pitch,
                  velocity: step.velocity,
                  scheduledTime: hardwareTime,
                );
              }
            }
          }
        }
      } else {
        // Sequencer / Pattern Playback Logic
        final int patternStep = stepIdx % currentPattern.lengthSteps;
        if (patternStep < track.steps.length) {
          final step = track.steps[patternStep];
          if (step.active) {
            audioEngine.playNoteOrSample(
              track: track,
              midiNote: step.pitch,
              velocity: step.velocity,
              scheduledTime: hardwareTime,
            );
          }
        }

        for (final note in track.notes) {
          if (note.startStep.toInt() == patternStep) {
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
  }

  // Step Editing
  void toggleStep(TrackChannel track, int stepIndex) {
    if (stepIndex >= 0 && stepIndex < track.steps.length) {
      final step = track.steps[stepIndex];
      step.active = !step.active;
      
      if (step.active) {
        // Add matching note for Piano Roll
        track.notes.removeWhere((n) => n.startStep.toInt() == stepIndex && n.pitch == step.pitch);
        track.notes.add(Note(
          id: 'step_${track.id}_$stepIndex',
          pitch: step.pitch,
          startStep: stepIndex.toDouble(),
          durationSteps: 1.0,
          velocity: step.velocity,
        ));
        audioEngine.playNoteOrSample(
          track: track,
          midiNote: step.pitch,
          velocity: step.velocity,
        );
      } else {
        // Remove matching note
        track.notes.removeWhere((n) => n.startStep.toInt() == stepIndex && n.pitch == step.pitch);
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

  // Lua Engine Compilation & Hot Swap
  void compileLuaCode(String code) {
    luaCode = code;
    compilationResult = LuaEngine.compile(code);

    if (compilationResult.isSuccess) {
      // Synchronize Lua parameters to active track
      activeTrack.luaScriptCode = code;
      for (final p in compilationResult.params) {
        activeTrack.luaParams[p.name] ??= p.defaultValue;
      }
    }
    notifyListeners();
  }

  void compileWrenCode(String code) => compileLuaCode(code);

  void loadLuaPreset(LuaPreset preset) {
    luaCode = preset.code;
    compileLuaCode(preset.code);
  }

  void loadWrenPreset(dynamic preset) {
    if (preset is LuaPreset) {
      loadLuaPreset(preset);
    } else {
      compileLuaCode(preset.code);
    }
  }

  void updateLuaParam(String paramName, double value) {
    activeTrack.luaParams[paramName] = value;
    notifyListeners();
  }

  void updateWrenParam(String paramName, double value) => updateLuaParam(paramName, value);

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
