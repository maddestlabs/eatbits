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
  final Map<String, web.AudioBuffer> _irWebBufferCache = {};
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
    List<double>? convolutionIrBuffer,
    String? convolutionIrName,
    double convolutionMix = 0.0,
    List<dynamic>? fxRack,
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

      // WebAudio Native Multi-FX C++ Audio Graph Chain
      web.AudioNode currentNode = source;

      if (fxRack != null && fxRack.isNotEmpty) {
        for (final fx in fxRack) {
          if (fx == null) continue;
          final bool enabled = fx.enabled == true;
          if (!enabled) continue;

          final String fxName = (fx.name ?? '').toString();
          final String fxTypeName = (fx.type?.toString() ?? '');
          final Map<dynamic, dynamic> params = (fx.params as Map?) ?? {};
          final double mix = ((fx.mix as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);

          if (fxTypeName.contains('convolutionReverb') || fxName == 'Convolution Reverb') {
            final dryLevel = ((params['DryLevel'] as num?)?.toDouble() ?? (1.0 - mix)).clamp(0.0, 2.0);
            final wetLevel = ((params['WetLevel'] as num?)?.toDouble() ?? mix).clamp(0.0, 2.0);
            final String irName = (fx.irSampleName ?? convolutionIrName ?? 'Great Hall').toString();

            web.AudioBuffer? irBuf = _irWebBufferCache[irName];
            if (irBuf == null && convolutionIrBuffer != null && convolutionIrBuffer.isNotEmpty) {
              irBuf = _audioContext!.createBuffer(1, convolutionIrBuffer.length, 44100);
              final irData = irBuf.getChannelData(0).toDart;
              for (int i = 0; i < convolutionIrBuffer.length; i++) {
                irData[i] = convolutionIrBuffer[i];
              }
              _irWebBufferCache[irName] = irBuf;
            }

            if (irBuf != null) {
              final nextBus = _audioContext!.createGain();
              final dryGain = _audioContext!.createGain();
              dryGain.gain.value = dryLevel;

              final wetGain = _audioContext!.createGain();
              wetGain.gain.value = wetLevel;

              final convolver = _audioContext!.createConvolver();
              convolver.buffer = irBuf;

              currentNode.connect(dryGain);
              dryGain.connect(nextBus);

              currentNode.connect(convolver);
              convolver.connect(wetGain);
              wetGain.connect(nextBus);

              currentNode = nextBus;
            }
          } else if (fxTypeName.contains('delay') || fxName == 'Stereo Delay') {
            final timeMs = ((params['TimeMs'] as num?)?.toDouble() ?? 250.0).clamp(10.0, 1000.0);
            final feedback = ((params['Feedback'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 0.95);

            final nextBus = _audioContext!.createGain();
            final delayNode = _audioContext!.createDelay(2.0);
            delayNode.delayTime.value = timeMs / 1000.0;

            final fbGain = _audioContext!.createGain();
            fbGain.gain.value = feedback;

            final dryGain = _audioContext!.createGain();
            dryGain.gain.value = 1.0 - mix;

            final wetGain = _audioContext!.createGain();
            wetGain.gain.value = mix;

            delayNode.connect(fbGain);
            fbGain.connect(delayNode);

            currentNode.connect(dryGain);
            dryGain.connect(nextBus);

            currentNode.connect(delayNode);
            delayNode.connect(wetGain);
            wetGain.connect(nextBus);

            currentNode = nextBus;
          } else if (fxTypeName.contains('biquadFilter') || fxName == 'Lowpass Filter') {
            final cutoff = ((params['Cutoff'] as num?)?.toDouble() ?? 3500.0).clamp(20.0, 20000.0);
            final res = ((params['Resonance'] as num?)?.toDouble() ?? 1.5).clamp(0.1, 20.0);

            final filterNode = _audioContext!.createBiquadFilter();
            filterNode.type = 'lowpass';
            filterNode.frequency.value = cutoff;
            filterNode.Q.value = res;

            currentNode.connect(filterNode);
            currentNode = filterNode;
          }
        }
      }

      currentNode.connect(trackGain);
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
