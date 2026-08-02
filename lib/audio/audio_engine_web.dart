import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class AudioEngineWebImpl {
  web.AudioContext? _audioContext;
  web.GainNode? _masterGainNode;
  web.AnalyserNode? _analyserNode;

  final Map<String, web.AudioNode> _nodeRegistry = {};
  final Map<String, web.AudioParam> _paramRegistry = {};
  final Map<String, web.AudioBufferSourceNode> _activeTrackSources = {};
  int _nodeCounter = 0;

  bool _initialized = false;
  bool get isInitialized => _initialized;
  double get currentTime => (_audioContext?.currentTime ?? 0.0).toDouble();

  AudioEngineWebImpl() {
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

  String createNode(String type, Map<String, dynamic> config) {
    if (_audioContext == null) return 'node_mock_${++_nodeCounter}';
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

  void connect(String sourceId, String targetId, [int outputIndex = 0, int inputIndex = 0]) {
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
    final node = _nodeRegistry[nodeId];
    if (node != null) {
      try {
        node.disconnect();
      } catch (e) {
        debugPrint('Error disconnecting node $nodeId: $e');
      }
    }
  }

  void scheduleParamOp({
    required String nodeId,
    required String paramName,
    required String method,
    required double value,
    required double scheduledTime,
    double? timeConstant,
  }) {
    if (_audioContext == null) return;
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

  void updateMeters(Uint8List timeData, Function(double l, double r) setPeaks) {
    if (_analyserNode == null) return;
    try {
      final jsArray = timeData.toJS;
      _analyserNode!.getByteTimeDomainData(jsArray);

      double sumSquareL = 0.0;
      double sumSquareR = 0.0;
      for (int i = 0; i < timeData.length; i++) {
        final val = (timeData[i] - 128) / 128.0;
        if (i % 2 == 0) {
          sumSquareL += val * val;
        } else {
          sumSquareR += val * val;
        }
      }
      final rmsL = math.sqrt(sumSquareL / (timeData.length / 2));
      final rmsR = math.sqrt(sumSquareR / (timeData.length / 2));

      setPeaks((rmsL * 2.5).clamp(0.0, 1.0), (rmsR * 2.5).clamp(0.0, 1.0));
    } catch (e) {
      // Ignore meter read errors
    }
  }

  void playPcmBuffer(
    List<double> samples,
    double volume,
    double pan, [
    double? scheduledTime,
    String? trackId,
    bool isMonophonic = false,
    bool isSlide = false,
    bool loop = false,
  ]) {
    if (_audioContext == null) return;
    try {
      if (isMonophonic && trackId != null) {
        final prevSource = _activeTrackSources[trackId];
        if (prevSource != null) {
          try {
            if (scheduledTime != null && scheduledTime > 0) {
              prevSource.stop(scheduledTime);
            } else {
              prevSource.stop();
            }
          } catch (_) {}
        }
      }

      final audioBuf = _audioContext!.createBuffer(1, samples.length, 44100);
      final channelData = audioBuf.getChannelData(0).toDart;
      for (int i = 0; i < samples.length; i++) {
        channelData[i] = samples[i];
      }

      final source = _audioContext!.createBufferSource();
      source.buffer = audioBuf;
      if (loop) {
        source.loop = true;
      }

      if (trackId != null) {
        _activeTrackSources[trackId] = source;
      }

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

  void stopTrackNotes(String trackId) {
    if (_audioContext == null) return;
    try {
      final prevSource = _activeTrackSources[trackId];
      if (prevSource != null) {
        try {
          final now = currentTime;
          prevSource.stop(now + 0.03);
        } catch (_) {
          try {
            prevSource.stop();
          } catch (_) {}
        }
        _activeTrackSources.remove(trackId);
      }
    } catch (e) {
      debugPrint('Error stopping WebAudio track notes: $e');
    }
  }
}
