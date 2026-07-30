import 'dart:math' as math;

/// Represents a snapshot of the DAW's playback position and transport state.
/// This unified clock structure bridges real-time audio scheduling with
/// 60fps visual/video frame indexing.
class TimeContext {
  final double bpm;
  final int timeSignatureNumerator;
  final int timeSignatureDenominator;
  final double currentBar; // Absolute bar position (e.g. 1.5 = Bar 1, Beat 3 in 4/4)
  final double currentBeat; // Absolute beat position from start (0.0, 1.0, 2.0...)
  final double audioTimeSeconds; // Absolute audio clock timestamp in seconds
  final double frameRate; // Target video/visual FPS (default 60.0)

  const TimeContext({
    required this.bpm,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    required this.currentBar,
    required this.currentBeat,
    required this.audioTimeSeconds,
    this.frameRate = 60.0,
  });

  /// Derived 60fps video/visual frame index based on absolute audio time.
  int get frameIndex => (audioTimeSeconds * frameRate).floor();

  /// Sub-frame fractional progress (0.0 to 1.0) between current and next visual frame.
  double get frameFraction => (audioTimeSeconds * frameRate) - frameIndex;

  /// Duration of a single beat in seconds.
  double get secondsPerBeat => 60.0 / math.max(1.0, bpm);

  /// Duration of a single bar in seconds.
  double get secondsPerBar => secondsPerBeat * timeSignatureNumerator;

  /// Converts a musical beat offset to seconds.
  double beatsToSeconds(double beats) => beats * secondsPerBeat;

  /// Converts seconds to a musical beat count.
  double secondsToBeats(double seconds) => seconds / secondsPerBeat;

  /// Converts a musical bar position to seconds.
  double barsToSeconds(double bars) => bars * secondsPerBar;

  /// Creates a TimeContext from absolute beat position and transport state.
  factory TimeContext.fromBeat({
    required double beat,
    required double bpm,
    int numerator = 4,
    int denominator = 4,
    double frameRate = 60.0,
  }) {
    final secPerBeat = 60.0 / math.max(1.0, bpm);
    final audioSec = beat * secPerBeat;
    final bar = (beat / numerator) + 1.0;

    return TimeContext(
      bpm: bpm,
      timeSignatureNumerator: numerator,
      timeSignatureDenominator: denominator,
      currentBar: bar,
      currentBeat: beat,
      audioTimeSeconds: audioSec,
      frameRate: frameRate,
    );
  }

  /// Converts TimeContext state into a map for passing into Lua scripts.
  Map<String, dynamic> toLuaTable() {
    return {
      'bpm': bpm,
      'timeSignatureNumerator': timeSignatureNumerator,
      'timeSignatureDenominator': timeSignatureDenominator,
      'bar': currentBar,
      'beat': currentBeat,
      'seconds': audioTimeSeconds,
      'frameIndex': frameIndex,
      'frameFraction': frameFraction,
    };
  }

  TimeContext copyWith({
    double? bpm,
    int? timeSignatureNumerator,
    int? timeSignatureDenominator,
    double? currentBar,
    double? currentBeat,
    double? audioTimeSeconds,
    double? frameRate,
  }) {
    return TimeContext(
      bpm: bpm ?? this.bpm,
      timeSignatureNumerator: timeSignatureNumerator ?? this.timeSignatureNumerator,
      timeSignatureDenominator: timeSignatureDenominator ?? this.timeSignatureDenominator,
      currentBar: currentBar ?? this.currentBar,
      currentBeat: currentBeat ?? this.currentBeat,
      audioTimeSeconds: audioTimeSeconds ?? this.audioTimeSeconds,
      frameRate: frameRate ?? this.frameRate,
    );
  }
}
