import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import '../models/track_model.dart';
import '../lua/lua_engine.dart';
import 'poly_synth.dart';

class AudioEngine {
  web.AudioContext? _audioContext;
  web.GainNode? _masterGainNode;
  web.AnalyserNode? _analyserNode;

  final Map<String, web.AudioNode> _nodeRegistry = {};
  final Map<String, web.AudioParam> _paramRegistry = {};
  int _nodeCounter = 0;

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

  // Double-buffered feedback metering snapshot channel
  Map<String, double> getMeterSnapshot() {
    updateMeters();
    return {
      'leftPeak': _leftPeak,
      'rightPeak': _rightPeak,
      'rms': (_leftPeak + _rightPeak) / 2.0,
      'currentTime': currentTime,
    };
  }

  // Node Registry & Factory Primitive
  String createNode(String type, Map<String, dynamic> config) {
    if (!kIsWeb || _audioContext == null) {
      return 'node_mock_${++_nodeCounter}';
    }

    final String nodeId = 'node_${type.toLowerCase()}_${++_nodeCounter}';

    try {
      if (type == 'StereoDelayFX') {
        final delayNode = _audioContext!.createDelay((config['maxTime'] as num?)?.toDouble() ?? 2.0);
        delayNode.delayTime.value = ((config['timeMs'] as num?)?.toDouble() ?? 250.0) / 1000.0;
        _nodeRegistry[nodeId] = delayNode;
        _paramRegistry['$nodeId:TimeMs'] = delayNode.delayTime;
      } else if (type == 'LFO') {
        final osc = _audioContext!.createOscillator();
        osc.type = (config['shape'] as String?) ?? 'sine';
        osc.frequency.value = (config['rateHz'] as num?)?.toDouble() ?? 2.0;
        osc.start();
        _nodeRegistry[nodeId] = osc;
        _paramRegistry['$nodeId:Frequency'] = osc.frequency;
      } else if (type == 'TB303' || type == 'ProceduralKick' || type == 'FMSynth') {
        final gain = _audioContext!.createGain();
        final filter = _audioContext!.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = (config['cutoff'] as num?)?.toDouble() ?? 1600.0;
        filter.Q.value = (config['resonance'] as num?)?.toDouble() ?? 6.0;

        filter.connect(gain);
        _nodeRegistry[nodeId] = gain;
        _paramRegistry['$nodeId:Cutoff'] = filter.frequency;
        _paramRegistry['$nodeId:Resonance'] = filter.Q;
        _paramRegistry['$nodeId:Gain'] = gain.gain;
      } else {
        final gain = _audioContext!.createGain();
        gain.gain.value = 1.0;
        _nodeRegistry[nodeId] = gain;
        _paramRegistry['$nodeId:Gain'] = gain.gain;
      }
    } catch (e) {
      debugPrint('Error creating WebAudio node $type: $e');
    }

    return nodeId;
  }

  // Audio Graph Routing Primitives
  void connect(String sourceId, String targetId, [int outputIndex = 0, int inputIndex = 0]) {
    if (!kIsWeb) return;
    final source = _nodeRegistry[sourceId];
    final target = _nodeRegistry[targetId] ?? _masterGainNode;

    if (source != null && target != null) {
      try {
        source.connect(target);
      } catch (e) {
        debugPrint('Error connecting WebAudio graph nodes ($sourceId -> $targetId): $e');
      }
    }
  }

  void connectToParam(String sourceId, String targetNodeId, String paramName) {
    if (!kIsWeb) return;
    final source = _nodeRegistry[sourceId];
    final paramKey = '$targetNodeId:$paramName';
    final param = _paramRegistry[paramKey];

    if (source != null && param != null) {
      try {
        source.connect(param);
      } catch (e) {
        debugPrint('Error connecting source $sourceId to AudioParam $paramKey: $e');
      }
    }
  }

  void disconnect(String nodeId) {
    if (!kIsWeb) return;
    final node = _nodeRegistry[nodeId];
    if (node != null) {
      try {
        node.disconnect();
      } catch (e) {
        debugPrint('Error disconnecting node $nodeId: $e');
      }
    }
  }

  // Sample-Accurate Parameter Automation Timeline Scheduling
  void scheduleParamOp({
    required String nodeId,
    required String paramName,
    required String method,
    required double value,
    required double scheduledTime,
    double? timeConstant,
  }) {
    if (!kIsWeb || _audioContext == null) return;
    final paramKey = '$nodeId:$paramName';
    final param = _paramRegistry[paramKey];

    if (param == null) return;

    final targetTime = scheduledTime > 0 ? scheduledTime : currentTime;

    try {
      switch (method) {
        case 'setValue':
          param.setValueAtTime(value, targetTime);
          break;
        case 'linearRamp':
          param.linearRampToValueAtTime(value, targetTime);
          break;
        case 'exponentialRamp':
          param.exponentialRampToValueAtTime(value.clamp(0.0001, 20000.0), targetTime);
          break;
        case 'setTarget':
          param.setTargetAtTime(value, targetTime, timeConstant ?? 0.1);
          break;
        default:
          param.setValueAtTime(value, targetTime);
          break;
      }
    } catch (e) {
      debugPrint('Error scheduling AudioParam op ($method on $paramKey): $e');
    }
  }

  // Command Queue Dispatcher for Wren Script Command Messages
  void processCommandQueue(List<Map<String, dynamic>> commands) {
    for (final cmd in commands) {
      final type = cmd['type'] as String?;
      if (type == 'CREATE_NODE') {
        createNode(cmd['nodeType'] as String, cmd['config'] as Map<String, dynamic>? ?? {});
      } else if (type == 'CONNECT') {
        connect(cmd['sourceId'] as String, cmd['targetId'] as String);
      } else if (type == 'CONNECT_PARAM') {
        connectToParam(cmd['sourceId'] as String, cmd['targetNodeId'] as String, cmd['paramName'] as String);
      } else if (type == 'PARAM_AUTOMATE') {
        scheduleParamOp(
          nodeId: cmd['nodeId'] as String,
          paramName: cmd['paramName'] as String,
          method: cmd['method'] as String,
          value: (cmd['value'] as num).toDouble(),
          scheduledTime: (cmd['scheduledTime'] as num).toDouble(),
          timeConstant: (cmd['timeConstant'] as num?)?.toDouble(),
        );
      } else if (type == 'NOTE_ON') {
        final note = (cmd['pitch'] as num).toInt();
        final vel = (cmd['velocity'] as num).toDouble();
        final time = (cmd['time'] as num).toDouble();
        final dur = (cmd['duration'] as num).toDouble();
        _playPcmBuffer(
          PolySynth.generateSynthToneBuffer(midiNote: note, waveform: 'sawtooth', lengthSec: dur),
          vel,
          0.0,
          time,
        );
      }
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

  double get currentTime => (_audioContext?.currentTime ?? 0.0).toDouble();

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
    } else if (track.type == TrackType.luaScript) {
      // Render custom Lua DSP synth sound sample
      pcmBuffer = List<double>.filled((44100 * durationSec).toInt(), 0.0);
      final double freq = PolySynth.midiToFreq(midiNote);

      for (int i = 0; i < pcmBuffer.length; i++) {
        final double t = i / 44100.0;
        pcmBuffer[i] = LuaEngine.evaluateSynth(
          code: track.luaScriptCode,
          time: t,
          freq: freq,
          note: midiNote,
          params: track.luaParams,
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
        final processed = LuaEngine.evaluateEffect(
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
