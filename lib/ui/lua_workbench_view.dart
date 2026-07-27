import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import '../lua/lua_preset_library.dart';
import 'widgets/eatbits_slider.dart';

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
    final tracks = widget.dawState.activePattern.tracks;
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
            color: DawTheme.panelHeader,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code, color: DawTheme.accentGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'LUA SCRIPT EDITOR',
                      style: DawTheme.getPrimaryFontStyle(
                        color: DawTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Active Track Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: DawTheme.controlBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: activeTrack.color, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: widget.dawState.activeTrackIndex,
                          dropdownColor: DawTheme.panelBackground,
                          items: List.generate(tracks.length, (idx) {
                            final t = tracks[idx];
                            return DropdownMenuItem<int>(
                              value: idx,
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.name,
                                    style: DawTheme.getPrimaryFontStyle(color: DawTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }),
                          onChanged: (idx) {
                            if (idx != null) {
                              widget.dawState.activeTrackIndex = idx;
                              final newTrack = tracks[idx];
                              _lastTrackId = newTrack.id;
                              _codeController.text = newTrack.luaScriptCode;
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Preset Loader Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: DawTheme.controlBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<LuaPreset>(
                          hint: Text('LOAD PRESET', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textSecondary, fontSize: 11)),
                          dropdownColor: DawTheme.panelBackground,
                          items: LuaPresetLibrary.presets.map((preset) {
                            return DropdownMenuItem<LuaPreset>(
                              value: preset,
                              child: Text(
                                preset.name,
                                style: DawTheme.getPrimaryFontStyle(color: DawTheme.textPrimary, fontSize: 11),
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

                    // Compile & Run Button
                    ElevatedButton.icon(
                      onPressed: () {
                        activeTrack.luaScriptCode = _codeController.text;
                        activeTrack.type = TrackType.luaScript;
                        widget.dawState.compileLuaCode(_codeController.text);
                      },
                      icon: Icon(Icons.play_arrow, size: 16, color: DawTheme.backgroundDark),
                      label: Text('COMPILE LUA DSP', style: DawTheme.getPrimaryFontStyle(color: DawTheme.backgroundDark, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DawTheme.accentGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
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
                // Real-time Audio Waveform Display
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DawTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DawTheme.accentGreen.withOpacity(0.4)),
                  ),
                  child: CustomPaint(
                    painter: WaveformPainter(timeData: widget.dawState.audioEngine.waveformTimeData),
                  ),
                ),

                const SizedBox(height: 12),

                // Code Editor Container
                Container(
                  decoration: BoxDecoration(
                    color: DawTheme.panelBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2B3245)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: DawTheme.panelHeader,
                        child: Row(
                          children: [
                            Icon(Icons.terminal, size: 14, color: DawTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'LUA SOURCE: ${activeTrack.name.toUpperCase()}',
                              style: DawTheme.getPrimaryFontStyle(color: DawTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        controller: _codeController,
                        maxLines: 14,
                        style: DawTheme.getDisplayFontStyle(
                          color: DawTheme.textPrimary,
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
                    color: result.isSuccess ? DawTheme.accentGreen.withOpacity(0.1) : DawTheme.muteColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: result.isSuccess ? DawTheme.accentGreen.withOpacity(0.5) : DawTheme.muteColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.isSuccess ? Icons.check_circle : Icons.error_outline,
                        color: result.isSuccess ? DawTheme.accentGreen : DawTheme.muteColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.errorMessage,
                          style: DawTheme.getDisplayFontStyle(
                            color: result.isSuccess ? DawTheme.accentGreen : DawTheme.muteColor,
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
                    style: DawTheme.getPrimaryFontStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12),
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
                          color: DawTheme.panelBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: DawTheme.primaryCyan.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  param.name,
                                  style: DawTheme.getPrimaryFontStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                Text(
                                  currentVal.toStringAsFixed(1),
                                  style: DawTheme.getDisplayFontStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),

                            EatBitsSlider(
                              value: currentVal.clamp(param.min, param.max),
                              min: param.min,
                              max: param.max,
                              defaultValue: param.defaultValue,
                              label: param.name,
                              activeColor: DawTheme.primaryCyan,
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
    if (timeData.isEmpty) return;

    final paint = Paint()
      ..color = DawTheme.accentGreen
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
