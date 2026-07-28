import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import 'widgets/eatbits_slider.dart';
import 'widgets/skeuomorphic_hardware_knob.dart';
import 'widgets/grungy_rack_panel.dart';
import 'widgets/glowing_nixie_display.dart';

class TrackInspectorView extends StatelessWidget {
  final DawState dawState;

  const TrackInspectorView({super.key, required this.dawState});

  @override
  Widget build(BuildContext context) {
    final track = dawState.activeTrack;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Track Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DawTheme.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: track.color, width: 2),
              boxShadow: [
                BoxShadow(color: track.color.withOpacity(0.2), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 48,
                  decoration: BoxDecoration(color: track.color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onDoubleTap: () {
                    // DOUBLE TAP TRACK TITLE: Navigate to Scripts Section (tab 4)
                    dawState.activeTabIndex = 4;
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name.toUpperCase(),
                        style: DawTheme.getPrimaryFontStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'TYPE: ${track.type.name.toUpperCase()} (DOUBLE-TAP FOR CODE)',
                        style: DawTheme.getPrimaryFontStyle(color: track.color, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Mute & Solo
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => dawState.toggleMute(track),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: track.isMuted ? DawTheme.muteColor : DawTheme.panelHeader,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('MUTE', style: DawTheme.getPrimaryFontStyle(color: track.isMuted ? Colors.white : DawTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => dawState.toggleSolo(track),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: track.isSoloed ? DawTheme.soloColor : DawTheme.panelHeader,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('SOLO', style: DawTheme.getPrimaryFontStyle(color: track.isSoloed ? Colors.black : DawTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Mixer Controls Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DawTheme.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2B3245)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHANNEL MIXER SETTINGS', style: DawTheme.getPrimaryFontStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 12),

                // Volume Slider
                Row(
                  children: [
                    SizedBox(width: 70, child: Text('VOLUME', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textSecondary, fontSize: 11))),
                    Expanded(
                      child: EatBitsSlider(
                        value: track.volume,
                        min: 0.0,
                        max: 1.5,
                        defaultValue: 1.0,
                        label: '${track.name} Volume',
                        activeColor: track.color,
                        onChanged: (val) => dawState.setTrackVolume(track, val),
                      ),
                    ),
                    SizedBox(width: 45, child: Text('${(track.volume * 100).toInt()}%', style: DawTheme.getDisplayFontStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),

                // Pan Slider
                Row(
                  children: [
                    SizedBox(width: 70, child: Text('PAN', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textSecondary, fontSize: 11))),
                    Expanded(
                      child: EatBitsSlider(
                        value: track.pan,
                        min: -1.0,
                        max: 1.0,
                        defaultValue: 0.0,
                        label: '${track.name} Pan',
                        activeColor: track.color,
                        onChanged: (val) => dawState.setTrackPan(track, val),
                      ),
                    ),
                    SizedBox(width: 45, child: Text(track.pan == 0 ? 'C' : (track.pan < 0 ? 'L${(track.pan.abs() * 100).toInt()}' : 'R${(track.pan * 100).toInt()}'), style: DawTheme.getDisplayFontStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),
              ],
            ),
          ),


          const SizedBox(height: 16),

          // Dynamic Lua Script Parameters (Exposed by Code)
          if ((track.type == TrackType.luaScript || track.luaParams.isNotEmpty) && dawState.compilationResult.params.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DawTheme.panelBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DawTheme.accentGreen.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code, color: DawTheme.accentGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'DYNAMIC SCRIPT PARAMETERS (CODE DRIVEN)',
                        style: DawTheme.getPrimaryFontStyle(color: DawTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...dawState.compilationResult.params.map((paramDef) {
                    final currentVal = (track.luaParams[paramDef.name] ?? paramDef.defaultValue).clamp(paramDef.min, paramDef.max);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text(paramDef.name, style: DawTheme.getPrimaryFontStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(
                            child: EatBitsSlider(
                              value: currentVal,
                              min: paramDef.min,
                              max: paramDef.max,
                              defaultValue: paramDef.defaultValue,
                              label: paramDef.name,
                              activeColor: DawTheme.accentGreen,
                              onChanged: (val) {
                                dawState.updateLuaParam(paramDef.name, val);
                              },
                            ),
                          ),
                          SizedBox(width: 55, child: Text(currentVal.toStringAsFixed(1), style: DawTheme.getDisplayFontStyle(color: DawTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // FX Insert Rack
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DawTheme.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2B3245)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FX INSERT RACK', style: DawTheme.getPrimaryFontStyle(color: DawTheme.secondaryMagenta, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Bitcrusher 8-Bit', style: DawTheme.getPrimaryFontStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text('Sample & bit depth reducer', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textMuted, fontSize: 10)),
                  value: track.fxRack.any((f) => f.name == 'Bitcrusher'),
                  activeColor: DawTheme.secondaryMagenta,
                  onChanged: (val) => dawState.toggleBitcrusher(track, val),
                ),
                SwitchListTile(
                  title: Text('Tube Distortion', style: DawTheme.getPrimaryFontStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text('Soft clipping saturation', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textMuted, fontSize: 10)),
                  value: track.fxRack.any((f) => f.name == 'TubeDistortion'),
                  activeColor: DawTheme.secondaryMagenta,
                  onChanged: (val) => dawState.toggleDistortion(track, val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Vintage Skeuomorphic Hardware Rack Unit (SILT / PunchBOX Style)
          GrungyRackPanel(
            title: 'Analog Hardware DSP Unit - SILT 808',
            subtitle: 'Real-Time Skeuomorphic Rotary Controls & Nixie Segment Readouts',
            accentColor: DawTheme.currentPreset == DawThemePreset.grungyHardware
                ? const Color(0xFFFF8C00)
                : track.color,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GlowingNixieDisplay(
                      label: 'GAIN OUTPUT',
                      valueText: '${(track.volume * 100).toInt()}',
                      unit: '%',
                      glowColor: DawTheme.currentPreset == DawThemePreset.grungyHardware
                          ? const Color(0xFFFF8C00)
                          : track.color,
                    ),
                    GlowingNixieDisplay(
                      label: 'STEREO POSITION',
                      valueText: track.pan == 0
                          ? 'CENTER'
                          : (track.pan < 0 ? 'L${(track.pan.abs() * 100).toInt()}' : 'R${(track.pan * 100).toInt()}'),
                      glowColor: DawTheme.currentPreset == DawThemePreset.grungyHardware
                          ? const Color(0xFFFF8C00)
                          : track.color,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SkeuomorphicHardwareKnob(
                      label: 'VOL GAIN',
                      value: track.volume,
                      min: 0.0,
                      max: 1.5,
                      defaultValue: 1.0,
                      accentColor: DawTheme.currentPreset == DawThemePreset.grungyHardware
                          ? const Color(0xFFFF8C00)
                          : track.color,
                      onChanged: (val) => dawState.setTrackVolume(track, val),
                      formatValue: (v) => '${(v * 100).toInt()}%',
                    ),
                    SkeuomorphicHardwareKnob(
                      label: 'PAN BALANCE',
                      value: track.pan,
                      min: -1.0,
                      max: 1.0,
                      defaultValue: 0.0,
                      accentColor: DawTheme.currentPreset == DawThemePreset.grungyHardware
                          ? const Color(0xFFFF8C00)
                          : track.color,
                      onChanged: (val) => dawState.setTrackPan(track, val),
                      formatValue: (v) => v == 0 ? 'CTR' : (v < 0 ? 'L${(v.abs() * 100).toInt()}' : 'R${(v * 100).toInt()}'),
                    ),
                    if (dawState.compilationResult.params.isNotEmpty) ...[
                      SkeuomorphicHardwareKnob(
                        label: dawState.compilationResult.params.first.name.toUpperCase(),
                        value: (track.luaParams[dawState.compilationResult.params.first.name] ??
                                dawState.compilationResult.params.first.defaultValue)
                            .clamp(
                              dawState.compilationResult.params.first.min,
                              dawState.compilationResult.params.first.max,
                            ),
                        min: dawState.compilationResult.params.first.min,
                        max: dawState.compilationResult.params.first.max,
                        defaultValue: dawState.compilationResult.params.first.defaultValue,
                        accentColor: DawTheme.accentGreen,
                        onChanged: (val) {
                          dawState.updateLuaParam(dawState.compilationResult.params.first.name, val);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

