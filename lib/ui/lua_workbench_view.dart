import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/eats_theme.dart';
import '../lua/lua_preset_library.dart';
import 'widgets/eatsbits_slider.dart';
import 'widgets/skeuomorphic_hardware_button.dart';

class LuaWorkbenchView extends StatefulWidget {
  final DawState dawState;

  const LuaWorkbenchView({super.key, required this.dawState});

  @override
  State<LuaWorkbenchView> createState() => _LuaWorkbenchViewState();
}

class _LuaWorkbenchViewState extends State<LuaWorkbenchView> {
  late TextEditingController _codeController;
  late String _lastTrackId;

  @override
  void initState() {
    super.initState();
    final activeTrack = widget.dawState.activeTrack;
    _lastTrackId = activeTrack.id;
    _codeController = TextEditingController(text: activeTrack.luaScriptCode);
  }

  @override
  void didUpdateWidget(covariant LuaWorkbenchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeTrack = widget.dawState.activeTrack;
    if (activeTrack.id != _lastTrackId) {
      _lastTrackId = activeTrack.id;
      _codeController.text = activeTrack.luaScriptCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTrack = widget.dawState.activeTrack;
    final result = widget.dawState.compilationResult;

    // Sync controller if external load happened
    if (_lastTrackId != activeTrack.id) {
      _lastTrackId = activeTrack.id;
      if (_codeController.text != activeTrack.luaScriptCode) {
        _codeController.text = activeTrack.luaScriptCode;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Track Selector & Presets
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: EatsTheme.panelHeader,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code, color: EatsTheme.accentGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'LUA SCRIPT EDITOR',
                      style: EatsTheme.getPrimaryFontStyle(
                        color: EatsTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preset Loader Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: EatsTheme.controlBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<LuaPreset>(
                          hint: Text('LOAD PRESET', style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textSecondary, fontSize: 11)),
                          dropdownColor: EatsTheme.panelBackground,
                          items: LuaPresetLibrary.presets.map((preset) {
                            return DropdownMenuItem<LuaPreset>(
                              value: preset,
                              child: Text(
                                preset.name,
                                style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textPrimary, fontSize: 11),
                              ),
                            );
                          }).toList(),
                          onChanged: (preset) {
                            if (preset != null) {
                              setState(() {
                                _codeController.text = preset.code;
                                activeTrack.luaScriptCode = preset.code;
                              });
                              widget.dawState.loadLuaPreset(preset);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Compile & Run Mechanical Hardware Button
                    SkeuomorphicHardwareButton(
                      label: 'COMPILE LUA DSP',
                      icon: Icons.play_arrow,
                      isActive: true,
                      activeColor: EatsTheme.accentGreen,
                      onTap: () {
                        activeTrack.luaScriptCode = _codeController.text;
                        activeTrack.type = TrackType.luaScript;
                        widget.dawState.compileLuaCode(_codeController.text);
                      },
                      height: 38,
                    ),

                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Real-time Audio Oscilloscope LCD Display
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D130E), // Vintage retro olive/black LCD screen
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2A3628), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0xB3000000), offset: Offset(0, 2), blurRadius: 4),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      children: [
                        // CRT Oscilloscope & Waveform Painter
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WaveformPainter(timeData: widget.dawState.audioEngine.waveformTimeData),
                          ),
                        ),

                        // Header Badge Overlay
                        Positioned(
                          top: 4,
                          left: 8,
                          child: Text(
                            'OSCILLOSCOPE [AUDIO OUT]',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: const Color(0xFF98B890).withOpacity(0.85),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        // Glass Glare Reflection Overlay
                        const Positioned.fill(
                          child: CustomPaint(
                            painter: _LcdOscilloscopeGlassReflectionPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Code Editor Container
                Container(
                  decoration: BoxDecoration(
                    color: EatsTheme.panelBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2B3245)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: EatsTheme.panelHeader,
                        child: Row(
                          children: [
                            Icon(Icons.terminal, size: 14, color: EatsTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'LUA SOURCE: ${activeTrack.name.toUpperCase()}',
                              style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        controller: _codeController,
                        maxLines: 14,
                        style: EatsTheme.getDisplayFontStyle(
                          color: EatsTheme.textPrimary,
                          fontSize: 12,
                        ).copyWith(height: 1.4),

                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(12),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Compiler Status & Output Console
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: result.isSuccess ? EatsTheme.accentGreen.withOpacity(0.1) : EatsTheme.muteColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: result.isSuccess ? EatsTheme.accentGreen.withOpacity(0.5) : EatsTheme.muteColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.isSuccess ? Icons.check_circle : Icons.error_outline,
                        color: result.isSuccess ? EatsTheme.accentGreen : EatsTheme.muteColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.errorMessage,
                          style: EatsTheme.getDisplayFontStyle(
                            color: result.isSuccess ? EatsTheme.accentGreen : EatsTheme.muteColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dynamic Lua Interactive Parameter Controls
                if (result.params.isNotEmpty) ...[
                  Text(
                    'LIVE SCRIPT PARAMETERS (${activeTrack.name})',
                    style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: result.params.map((param) {
                      final currentVal = activeTrack.luaParams[param.name] ?? param.defaultValue;

                      return Container(
                        width: 170,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: EatsTheme.panelBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: EatsTheme.primaryCyan.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  param.name,
                                  style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                Text(
                                  currentVal.toStringAsFixed(1),
                                  style: EatsTheme.getDisplayFontStyle(color: EatsTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),

                            EatsBitsSlider(
                              value: currentVal.clamp(param.min, param.max),
                              min: param.min,
                              max: param.max,
                              defaultValue: param.defaultValue,
                              label: param.name,
                              activeColor: EatsTheme.primaryCyan,
                              onChanged: (val) {
                                widget.dawState.updateLuaParam(param.name, val);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<int> timeData;

  WaveformPainter({required this.timeData});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw CRT Grid Division Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1B2A1C)
      ..strokeWidth = 1.0;

    final centerPaint = Paint()
      ..color = const Color(0xFF28402A)
      ..strokeWidth = 1.2;

    // Horizontal Divisions & Center Zero Baseline
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerPaint);

    for (double y = midY - 18; y > 0; y -= 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double y = midY + 18; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical Division Lines
    const numVertDivisions = 8;
    final vertStep = size.width / numVertDivisions;
    for (int i = 1; i < numVertDivisions; i++) {
      final vx = i * vertStep;
      canvas.drawLine(Offset(vx, 0), Offset(vx, size.height), gridPaint);
    }

    if (timeData.isEmpty) return;

    // Build Waveform Trace Path
    final path = Path();
    final sliceWidth = size.width / timeData.length;

    double x = 0;
    for (int i = 0; i < timeData.length; i++) {
      final v = timeData[i] / 128.0;
      final y = v * size.height / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      x += sliceWidth;
    }

    // Pass 1: Neon Green Outer CRT Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(path, glowPaint);

    // Pass 2: Bright Neon Core Trace Line
    final tracePaint = Paint()
      ..color = const Color(0xFFE5FFEC)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, tracePaint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}

class _LcdOscilloscopeGlassReflectionPainter extends CustomPainter {
  const _LcdOscilloscopeGlassReflectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glarePath = Path();
    glarePath.moveTo(0, 0);
    glarePath.lineTo(size.width, 0);
    glarePath.lineTo(size.width, size.height * 0.45);
    glarePath.close();

    final glarePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));

    canvas.drawPath(glarePath, glarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
