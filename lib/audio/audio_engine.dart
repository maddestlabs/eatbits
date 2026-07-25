import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import '../models/track_model.dart';
import '../wren/wren_engine.dart';
import 'poly_synth.dart';

class AudioEngine {
  web.AudioContext? _audioContext;
  web.GainNode? _masterGainNode;
  web.AnalyserNode? _analyserNode;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  double _leftPeak = 0.0;
  double _rightPeak = 0.0;
  double get leftPeak => _leftPeak;
  double get rightPeak => _rightPeak;

  final Uint8List _timeData = Uint8List(128);
  Uint8List get waveformTimeData => _timeData;

  AudioEngine() {
    _initWebAudio();
  }

  void _initWebAudio() {
    if (!kIsWeb) return;
    try {
      _audioContext = web.AudioContext();
      _masterGainNode = _audioContext!.createGain();
      _analyserNode = _audioContext!.createAnalyser();

      _analyserNode!.fftSize = 256;
      _masterGainNode!.connect(_analyserNode!);
      _analyserNode!.connect(_audioContext!.destination);

      _initialized = true;
    } catch (e) {
      debugPrint('WebAudio initialization error: $e');
    }
  }

  void ensureContextRunning() {
    if (_audioContext != null && _audioContext!.state == 'suspended') {
      _audioContext!.resume();
    }
  }

  void setMasterVolume(double volume) {
    if (_masterGainNode != null) {
      _masterGainNode!.gain.value = volume.clamp(0.0, 1.5);
    }
  }

  // Update peak meters for visualizers
  void updateMeters() {
    if (_analyserNode == null) return;
    try {
      final jsArray = _timeData.toJS;
      _analyserNode!.getByteTimeDomainData(jsArray);
      
      double sumSquareL = 0.0;
      double sumSquareR = 0.0;
      for (int i = 0; i < _timeData.length; i++) {
        final val = (_timeData[i] - 128) / 128.0;
        if (i % 2 == 0) {
          sumSquareL += val * val;
        } else {
          sumSquareR += val * val;
        }
      }
      final rmsL = math.sqrt(sumSquareL / (_timeData.length / 2));
      final rmsR = math.sqrt(sumSquareR / (_timeData.length / 2));

      _leftPeak = (rmsL * 2.5).clamp(0.0, 1.0);
      _rightPeak = (rmsR * 2.5).clamp(0.0, 1.0);
    } catch (e) {
      // Ignore meter read errors
    }
  }

  double get currentTime => _audioContext?.currentTime ?? 0.0;

  // Trigger Sound Sample / Note Playback with Hardware Sample-Exact Timing
  void playNoteOrSample({
    required TrackChannel track,
    required int midiNote,
    required double velocity,
    double durationSec = 0.4,
    double? scheduledTime,
  }) {
    if (!kIsWeb || _audioContext == null) return;
    ensureContextRunning();

    if (track.isMuted) return;

    List<double> pcmBuffer;

    if (track.type == TrackType.sampler) {
      switch (track.sampleName.toLowerCase()) {
        case 'snare':
          pcmBuffer = PolySynth.generateSnareBuffer();
          break;
        case 'hihat':
        case 'hi-hat':
          pcmBuffer = PolySynth.generateHiHatBuffer(open: false);
          break;
        case 'openhat':
          pcmBuffer = PolySynth.generateHiHatBuffer(open: true);
          break;
        case 'clap':
          pcmBuffer = PolySynth.generateClapBuffer();
          break;
        case 'kick':
        default:
          pcmBuffer = PolySynth.generateKickBuffer();
          break;
      }
    } else if (track.type == TrackType.wrenScript) {
      // Render custom Wren DSP synth sound sample
      pcmBuffer = List<double>.filled((44100 * durationSec).toInt(), 0.0);
      final double freq = PolySynth.midiToFreq(midiNote);

      for (int i = 0; i < pcmBuffer.length; i++) {
        final double t = i / 44100.0;
        pcmBuffer[i] = WrenEngine.evaluateSynth(
          code: track.wrenScriptCode,
          time: t,
          freq: freq,
          note: midiNote,
          params: track.wrenParams,
        );
      }
    } else {
      // Standard PolySynth (sawtooth/square/sine synth)
      pcmBuffer = PolySynth.generateSynthToneBuffer(
        midiNote: midiNote,
        waveform: track.synthWaveform,
        cutoff: track.cutoff,
        attack: track.attack,
        release: track.release,
        lengthSec: durationSec,
      );
    }

    // Apply active FX inserts
    for (final fx in track.fxRack) {
      if (!fx.enabled) continue;
      for (int i = 0; i < pcmBuffer.length; i++) {
        final t = i / 44100.0;
        final processed = WrenEngine.evaluateEffect(
          code: fx.name,
          inputSample: pcmBuffer[i],
          time: t,
          params: fx.params,
        );
        pcmBuffer[i] = (pcmBuffer[i] * (1.0 - fx.mix)) + (processed * fx.mix);
      }
    }

    _playPcmBuffer(pcmBuffer, track.volume * velocity, track.pan, scheduledTime);
  }

  void _playPcmBuffer(List<double> samples, double volume, double pan, [double? scheduledTime]) {
    try {
      final audioBuf = _audioContext!.createBuffer(1, samples.length, 44100);
      final channelData = audioBuf.getChannelData(0).toDart;
      for (int i = 0; i < samples.length; i++) {
        channelData[i] = samples[i];
      }

      final source = _audioContext!.createBufferSource();
      source.buffer = audioBuf;

      final trackGain = _audioContext!.createGain();
      trackGain.gain.value = volume;

      final panner = _audioContext!.createStereoPanner();
      panner.pan.value = pan.clamp(-1.0, 1.0);

      source.connect(trackGain);
      trackGain.connect(panner);
      panner.connect(_masterGainNode!);

      if (scheduledTime != null && scheduledTime > 0) {
        source.start(scheduledTime);
      } else {
        source.start();
      }
    } catch (e) {
      debugPrint('Error playing WebAudio PCM buffer: $e');
    }
  }
}
