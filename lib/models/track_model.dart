import 'package:flutter/material.dart';

enum MusicViewType { pianoRoll, tracker, script, score }
enum TrackType { sampler, synth, luaScript, bass;
  // Backward compatibility getter
  bool get isScript => this == TrackType.luaScript;
}

class Note {
  String id;
  int pitch; // MIDI Note Number (e.g., 60 = C4)
  double startStep; // Position in steps (0.0 to 32.0)
  double durationSteps; // Duration in steps (default 1.0)
  double velocity; // 0.0 to 1.0
  int column; // Tracker sub-channel column index (0..N)
  String effectCommand; // Hex effect command (e.g., "00", "V90", "P12")

  Note({
    required this.id,
    required this.pitch,
    required this.startStep,
    this.durationSteps = 1.0,
    this.velocity = 0.9,
    this.column = 0,
    this.effectCommand = '00',
  });

  Note copyWith({
    String? id,
    int? pitch,
    double? startStep,
    double? durationSteps,
    double? velocity,
    int? column,
    String? effectCommand,
  }) {
    return Note(
      id: id ?? this.id,
      pitch: pitch ?? this.pitch,
      startStep: startStep ?? this.startStep,
      durationSteps: durationSteps ?? this.durationSteps,
      velocity: velocity ?? this.velocity,
      column: column ?? this.column,
      effectCommand: effectCommand ?? this.effectCommand,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pitch': pitch,
    'startStep': startStep,
    'durationSteps': durationSteps,
    'velocity': velocity,
    'column': column,
    'effectCommand': effectCommand,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] ?? '',
    pitch: json['pitch'] ?? 60,
    startStep: (json['startStep'] as num?)?.toDouble() ?? 0.0,
    durationSteps: (json['durationSteps'] as num?)?.toDouble() ?? 1.0,
    velocity: (json['velocity'] as num?)?.toDouble() ?? 0.9,
    column: json['column'] ?? 0,
    effectCommand: json['effectCommand'] ?? '00',
  );
}

class StepEvent {
  bool active;
  double velocity;
  int pitch; // Default pitch for drum or note trigger

  StepEvent({
    this.active = false,
    this.velocity = 0.8,
    this.pitch = 60,
  });

  StepEvent copyWith({bool? active, double? velocity, int? pitch}) {
    return StepEvent(
      active: active ?? this.active,
      velocity: velocity ?? this.velocity,
      pitch: pitch ?? this.pitch,
    );
  }

  Map<String, dynamic> toJson() => {
    'active': active,
    'velocity': velocity,
    'pitch': pitch,
  };

  factory StepEvent.fromJson(Map<String, dynamic> json) => StepEvent(
    active: json['active'] ?? false,
    velocity: (json['velocity'] as num?)?.toDouble() ?? 0.8,
    pitch: json['pitch'] ?? 60,
  );
}

enum FXType { biquadFilter, delay, distortion, bitcrusher, luaFX }

class FXInsert {
  String id;
  String name;
  FXType type;
  bool enabled;
  double mix; // Dry/Wet 0.0 - 1.0
  Map<String, double> params; // e.g. 'cutoff': 2000, 'resonance': 3.0

  FXInsert({
    required this.id,
    required this.name,
    required this.type,
    this.enabled = true,
    this.mix = 0.5,
    required this.params,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'enabled': enabled,
    'mix': mix,
    'params': params,
  };

  factory FXInsert.fromJson(Map<String, dynamic> json) => FXInsert(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: FXType.values.firstWhere((e) => e.name == json['type'], orElse: () => FXType.biquadFilter),
    enabled: json['enabled'] ?? true,
    mix: (json['mix'] as num?)?.toDouble() ?? 0.5,
    params: Map<String, double>.from(json['params'] ?? {}),
  );
}

class MidiFXInsert {
  String id;
  String name;
  bool enabled;
  String luaScriptCode;
  Map<String, double> luaParams;

  MidiFXInsert({
    required this.id,
    required this.name,
    this.enabled = true,
    this.luaScriptCode = '',
    Map<String, double>? luaParams,
  }) : luaParams = luaParams ?? {};

  MidiFXInsert copyWith({
    String? id,
    String? name,
    bool? enabled,
    String? luaScriptCode,
    Map<String, double>? luaParams,
  }) {
    return MidiFXInsert(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      luaScriptCode: luaScriptCode ?? this.luaScriptCode,
      luaParams: luaParams ?? Map.from(this.luaParams),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'enabled': enabled,
    'luaScriptCode': luaScriptCode,
    'luaParams': luaParams,
  };

  factory MidiFXInsert.fromJson(Map<String, dynamic> json) => MidiFXInsert(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    enabled: json['enabled'] ?? true,
    luaScriptCode: json['luaScriptCode'] ?? '',
    luaParams: Map<String, double>.from(json['luaParams'] ?? {}),
  );
}

class TrackClip {
  String id;
  String name;
  String trackId;
  int startBar; // 0, 1, 2, 3...
  int barLength; // 1, 2, 4, 8...
  List<Note> notes;
  String luaScriptCode;
  Map<String, double> luaParams;
  List<Note>? evaluatedNotesCache;

  TrackClip({
    required this.id,
    required this.name,
    required this.trackId,
    this.startBar = 0,
    this.barLength = 4,
    List<Note>? notes,
    this.luaScriptCode = '',
    Map<String, double>? luaParams,
    this.evaluatedNotesCache,
  })  : notes = notes ?? [],
        luaParams = luaParams ?? {};

  TrackClip copyWith({
    String? id,
    String? name,
    String? trackId,
    int? startBar,
    int? barLength,
    List<Note>? notes,
    String? luaScriptCode,
    Map<String, double>? luaParams,
    List<Note>? evaluatedNotesCache,
  }) {
    return TrackClip(
      id: id ?? this.id,
      name: name ?? this.name,
      trackId: trackId ?? this.trackId,
      startBar: startBar ?? this.startBar,
      barLength: barLength ?? this.barLength,
      notes: notes ?? this.notes.map((n) => n.copyWith()).toList(),
      luaScriptCode: luaScriptCode ?? this.luaScriptCode,
      luaParams: luaParams ?? Map.from(this.luaParams),
      evaluatedNotesCache: evaluatedNotesCache ?? (this.evaluatedNotesCache != null ? this.evaluatedNotesCache!.map((n) => n.copyWith()).toList() : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trackId': trackId,
    'startBar': startBar,
    'barLength': barLength,
    'notes': notes.map((n) => n.toJson()).toList(),
    'luaScriptCode': luaScriptCode,
    'luaParams': luaParams,
  };

  factory TrackClip.fromJson(Map<String, dynamic> json) => TrackClip(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    trackId: json['trackId'] ?? '',
    startBar: json['startBar'] ?? 0,
    barLength: json['barLength'] ?? 4,
    notes: (json['notes'] as List?)?.map((n) => Note.fromJson(n)).toList() ?? [],
    luaScriptCode: json['luaScriptCode'] ?? '',
    luaParams: Map<String, double>.from(json['luaParams'] ?? {}),
  );
}

class TrackChannel {
  String id;
  String name;
  Color color;
  TrackType type;
  double volume; // 0.0 to 1.5
  double pan; // -1.0 to 1.0
  bool isMuted;
  bool isSoloed;
  
  // Instrument config
  String sampleName; // For sampler (kick, snare, hihat, clap, bass, synth)
  String synthWaveform; // sine, square, sawtooth, triangle
  double cutoff;
  double resonance;
  double attack;
  double release;

  // Lua engine plugin integration
  String luaScriptCode;
  Map<String, double> luaParams;

  // Backwards compatibility getters
  String get wrenScriptCode => luaScriptCode;
  set wrenScriptCode(String val) => luaScriptCode = val;
  Map<String, double> get wrenParams => luaParams;
  set wrenParams(Map<String, double> val) => luaParams = val;

  // Pattern steps & Piano Roll notes & Per-track clips
  List<StepEvent> steps; // 16 or 32 step grid
  List<Note> notes; // Active clip notes
  List<TrackClip> clips; // Per-track arrangement clips

  // FX Racks
  List<FXInsert> fxRack; // Audio FX Rack
  List<MidiFXInsert> midiFXRack; // MIDI FX Rack

  // Multi-View Config
  int trackerColumns; // Number of tracker sub-channel columns for polyphony (default 4)
  MusicViewType activeView; // Active view for this track (pianoRoll, tracker, score)

  TrackChannel({
    required this.id,
    required this.name,
    required this.color,
    required this.type,
    this.volume = 0.8,
    this.pan = 0.0,
    this.isMuted = false,
    this.isSoloed = false,
    this.sampleName = 'kick',
    this.synthWaveform = 'sawtooth',
    this.cutoff = 3000.0,
    this.resonance = 1.0,
    this.attack = 0.01,
    this.release = 0.3,
    String luaScriptCode = '',
    String wrenScriptCode = '',
    this.trackerColumns = 4,
    this.activeView = MusicViewType.pianoRoll,
    Map<String, double>? luaParams,
    Map<String, double>? wrenParams,
    List<StepEvent>? steps,
    List<Note>? notes,
    List<TrackClip>? clips,
    List<FXInsert>? fxRack,
    List<MidiFXInsert>? midiFXRack,
  })  : luaScriptCode = luaScriptCode.isNotEmpty ? luaScriptCode : wrenScriptCode,
        luaParams = luaParams ?? wrenParams ?? {},
        steps = steps ?? List.generate(32, (_) => StepEvent()),
        notes = notes ?? [],
        clips = clips ?? [],
        fxRack = fxRack ?? [],
        midiFXRack = midiFXRack ?? [];

  TrackChannel copyWith({
    String? id,
    String? name,
    Color? color,
    TrackType? type,
    double? volume,
    double? pan,
    bool? isMuted,
    bool? isSoloed,
    String? sampleName,
    String? synthWaveform,
    double? cutoff,
    double? resonance,
    double? attack,
    double? release,
    String? luaScriptCode,
    String? wrenScriptCode,
    int? trackerColumns,
    MusicViewType? activeView,
    Map<String, double>? luaParams,
    Map<String, double>? wrenParams,
    List<StepEvent>? steps,
    List<Note>? notes,
    List<TrackClip>? clips,
    List<FXInsert>? fxRack,
    List<MidiFXInsert>? midiFXRack,
  }) {
    return TrackChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      isMuted: isMuted ?? this.isMuted,
      isSoloed: isSoloed ?? this.isSoloed,
      sampleName: sampleName ?? this.sampleName,
      synthWaveform: synthWaveform ?? this.synthWaveform,
      cutoff: cutoff ?? this.cutoff,
      resonance: resonance ?? this.resonance,
      attack: attack ?? this.attack,
      release: release ?? this.release,
      luaScriptCode: luaScriptCode ?? wrenScriptCode ?? this.luaScriptCode,
      trackerColumns: trackerColumns ?? this.trackerColumns,
      activeView: activeView ?? this.activeView,
      luaParams: luaParams ?? wrenParams ?? Map.from(this.luaParams),
      steps: steps ?? this.steps.map((s) => s.copyWith()).toList(),
      notes: notes ?? this.notes.map((n) => n.copyWith()).toList(),
      clips: clips ?? this.clips.map((c) => c.copyWith()).toList(),
      fxRack: fxRack ?? List.from(this.fxRack),
      midiFXRack: midiFXRack ?? List.from(this.midiFXRack),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'type': type.name,
    'volume': volume,
    'pan': pan,
    'isMuted': isMuted,
    'isSoloed': isSoloed,
    'sampleName': sampleName,
    'synthWaveform': synthWaveform,
    'cutoff': cutoff,
    'resonance': resonance,
    'attack': attack,
    'release': release,
    'luaScriptCode': luaScriptCode,
    'wrenScriptCode': luaScriptCode,
    'trackerColumns': trackerColumns,
    'activeView': activeView.name,
    'luaParams': luaParams,
    'wrenParams': luaParams,
    'steps': steps.map((s) => s.toJson()).toList(),
    'notes': notes.map((n) => n.toJson()).toList(),
    'fxRack': fxRack.map((f) => f.toJson()).toList(),
    'midiFXRack': midiFXRack.map((f) => f.toJson()).toList(),
  };
}

class Pattern {
  String id;
  String name;
  int lengthSteps; // 16 or 32
  List<TrackChannel> tracks;

  Pattern({
    required this.id,
    required this.name,
    this.lengthSteps = 16,
    required this.tracks,
  });
}

class ArrangementItem {
  String patternId;
  int startBar;
  int barLength;

  ArrangementItem({
    required this.patternId,
    required this.startBar,
    this.barLength = 1,
  });
}
