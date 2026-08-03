import 'package:flutter/material.dart';
import '../audio/convolver_engine.dart';
import '../audio/soundfont_engine.dart';
import '../audio/soundfont_decoder.dart';


import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/eats_theme.dart';
import 'widgets/eatsbits_slider.dart';
import 'widgets/skeuomorphic_hardware_knob.dart';
import 'widgets/grungy_rack_panel.dart';
import 'widgets/glowing_nixie_display.dart';
import 'widgets/rename_track_dialog.dart';
import 'widgets/ir_pack_dialog.dart';
import 'widgets/modular_fx_rack_widget.dart';



class TrackInspectorView extends StatelessWidget {
  final DawState dawState;

  const TrackInspectorView({super.key, required this.dawState});

  Widget _buildSoundFontPresetSelector(BuildContext context, TrackChannel track) {
    final fontData = SoundFontEngine.instance.getSoundFont(track.sampleName);
    if (fontData == null || fontData.presets.isEmpty) return const SizedBox.shrink();

    final currentPresetNum = (track.luaParams['PresetNum'] ?? 0.0).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EatsTheme.panelBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EatsTheme.accentGreen, width: 1.5),
        boxShadow: [
          BoxShadow(color: EatsTheme.accentGreen.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.piano, color: EatsTheme.accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'SOUNDFONT BANK: ${track.sampleName.toUpperCase()}',
                style: EatsTheme.getPrimaryFontStyle(
                  color: EatsTheme.accentGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'SELECT PROGRAM PRESET (${fontData.presets.length} AVAILABLE):',
            style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: EatsTheme.panelHeader,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2B3245)),

            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: fontData.presets.any((p) => p.presetNum == currentPresetNum) ? currentPresetNum : fontData.presets.first.presetNum,
                isExpanded: true,
                dropdownColor: EatsTheme.panelHeader,
                style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                items: fontData.presets.map((preset) {
                  final label = GeneralMidiNames.getPresetDisplayName(preset.bankNum, preset.presetNum, preset.name);
                  return DropdownMenuItem<int>(
                    value: preset.presetNum,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (newPresetNum) {
                  if (newPresetNum != null) {
                    final p = fontData.presets.firstWhere((element) => element.presetNum == newPresetNum, orElse: () => fontData.presets.first);
                    dawState.updateLuaParam('PresetNum', p.presetNum.toDouble());
                    dawState.updateLuaParam('BankNum', p.bankNum.toDouble());
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModularFxRack(BuildContext context, TrackChannel track) {
    final availableIrs = ConvolverEngine.instance.getAvailableIrNames();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EatsTheme.panelBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EatsTheme.secondaryMagenta.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: EatsTheme.secondaryMagenta.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: EatsTheme.secondaryMagenta, size: 18),
              const SizedBox(width: 8),
              Text(
                'MODULAR FX INSERT RACK (${track.fxRack.length})',
                style: EatsTheme.getPrimaryFontStyle(
                  color: EatsTheme.secondaryMagenta,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 12),
                label: Text('IR PACKS', style: EatsTheme.getPrimaryFontStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EatsTheme.secondaryMagenta,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => IrPackDialog(
                      onInstalled: () => dawState.notifyListeners(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              PopupMenuButton<FXType>(
                tooltip: 'Add FX Insert',
                color: EatsTheme.panelHeader,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: EatsTheme.panelHeader,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: EatsTheme.secondaryMagenta),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: EatsTheme.secondaryMagenta, size: 14),
                      const SizedBox(width: 4),
                      Text('+ ADD FX', style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.secondaryMagenta, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: FXType.convolutionReverb, child: Text('Convolution Reverb')),
                  const PopupMenuItem(value: FXType.distortion, child: Text('Tube Distortion')),
                  const PopupMenuItem(value: FXType.bitcrusher, child: Text('Bitcrusher 8-Bit')),
                  const PopupMenuItem(value: FXType.delay, child: Text('Stereo Delay')),
                  const PopupMenuItem(value: FXType.biquadFilter, child: Text('Lowpass Filter')),
                ],
                onSelected: (type) => dawState.addFXInsert(track, type),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (track.fxRack.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No FX Inserts on this track. Click "+ ADD FX" to add Convolution Reverb, Distortion, or Bitcrusher.',
                  style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textMuted, fontSize: 11),
                ),
              ),
            )
          else
            ...track.fxRack.asMap().entries.map((entry) {
              final fx = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EatsTheme.panelHeader,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: fx.enabled ? EatsTheme.secondaryMagenta : const Color(0xFF2B3245)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: fx.enabled,
                          activeColor: EatsTheme.secondaryMagenta,
                          onChanged: (val) => dawState.toggleFXInsert(track, fx.id, val),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          fx.name.toUpperCase(),
                          style: EatsTheme.getPrimaryFontStyle(
                            color: fx.enabled ? EatsTheme.textPrimary : EatsTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: EatsTheme.textMuted, size: 18),
                          onPressed: () => dawState.removeFXInsert(track, fx.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dry/Wet Mix Slider
                    Row(
                      children: [
                        SizedBox(width: 80, child: Text('DRY/WET', style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textMuted, fontSize: 10))),
                        Expanded(
                          child: EatsBitsSlider(
                            value: fx.mix,
                            min: 0.0,
                            max: 1.0,
                            defaultValue: 0.5,
                            label: 'Dry/Wet',
                            activeColor: EatsTheme.secondaryMagenta,
                            onChanged: (val) => dawState.updateFXMix(track, fx.id, val),
                          ),
                        ),
                        SizedBox(width: 45, child: Text('${(fx.mix * 100).toInt()}%', style: EatsTheme.getDisplayFontStyle(color: EatsTheme.secondaryMagenta, fontSize: 10))),
                      ],
                    ),

                    // FX Specific Parameters
                    if (fx.type == FXType.convolutionReverb) ...[
                      const SizedBox(height: 8),
                      Text('IMPULSE RESPONSE (IR):', style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textMuted, fontSize: 10)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: EatsTheme.panelBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2B3245)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: availableIrs.contains(fx.irSampleName) ? fx.irSampleName : (availableIrs.isNotEmpty ? availableIrs.first : 'Great Hall'),
                            isExpanded: true,
                            dropdownColor: EatsTheme.panelBackground,
                            style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                            items: availableIrs.map((ir) => DropdownMenuItem(value: ir, child: Text(ir))).toList(),
                            onChanged: (newIr) {
                              if (newIr != null) dawState.updateFXIrSample(track, fx.id, newIr);
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      ...fx.params.entries.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              SizedBox(width: 80, child: Text(p.key.toUpperCase(), style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textMuted, fontSize: 10))),
                              Expanded(
                                child: EatsBitsSlider(
                                  value: p.value,
                                  min: p.key == 'Drive' ? 0.0 : 1.0,
                                  max: p.key == 'Drive' ? 1.0 : (p.key == 'Bits' ? 16.0 : 10000.0),
                                  defaultValue: p.key == 'Drive' ? 0.5 : (p.key == 'Bits' ? 8.0 : 3500.0),
                                  label: p.key,
                                  activeColor: EatsTheme.secondaryMagenta,
                                  onChanged: (val) => dawState.updateFXParam(track, fx.id, p.key, val),
                                ),
                              ),

                              SizedBox(width: 45, child: Text(p.value.toStringAsFixed(1), style: EatsTheme.getDisplayFontStyle(color: EatsTheme.secondaryMagenta, fontSize: 10))),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }



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
              color: EatsTheme.panelBackground,
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
                  onLongPress: () => showRenameTrackDialog(context, dawState, track),
                  onDoubleTap: () {
                    // DOUBLE TAP TRACK TITLE: Navigate to Scripts Section (tab 4)
                    dawState.activeTabIndex = 4;
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name.toUpperCase(),
                        style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'TYPE: ${track.type.name.toUpperCase()} (DOUBLE-TAP FOR CODE)',
                        style: EatsTheme.getPrimaryFontStyle(color: track.color, fontSize: 10, fontWeight: FontWeight.w600),
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
                          color: track.isMuted ? EatsTheme.muteColor : EatsTheme.panelHeader,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('MUTE', style: EatsTheme.getPrimaryFontStyle(color: track.isMuted ? Colors.white : EatsTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => dawState.toggleSolo(track),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: track.isSoloed ? EatsTheme.soloColor : EatsTheme.panelHeader,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('SOLO', style: EatsTheme.getPrimaryFontStyle(color: track.isSoloed ? Colors.black : EatsTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
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
              color: EatsTheme.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2B3245)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHANNEL MIXER SETTINGS', style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 12),

                // Volume Slider
                Row(
                  children: [
                    SizedBox(width: 70, child: Text('VOLUME', style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textSecondary, fontSize: 11))),
                    Expanded(
                      child: EatsBitsSlider(
                        value: track.volume,
                        min: 0.0,
                        max: 1.5,
                        defaultValue: 1.0,
                        label: '${track.name} Volume',
                        activeColor: track.color,
                        onChanged: (val) => dawState.setTrackVolume(track, val),
                      ),
                    ),
                    SizedBox(width: 45, child: Text('${(track.volume * 100).toInt()}%', style: EatsTheme.getDisplayFontStyle(color: EatsTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),

                // Pan Slider
                Row(
                  children: [
                    SizedBox(width: 70, child: Text('PAN', style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textSecondary, fontSize: 11))),
                    Expanded(
                      child: EatsBitsSlider(
                        value: track.pan,
                        min: -1.0,
                        max: 1.0,
                        defaultValue: 0.0,
                        label: '${track.name} Pan',
                        activeColor: track.color,
                        onChanged: (val) => dawState.setTrackPan(track, val),
                      ),
                    ),
                    SizedBox(width: 45, child: Text(track.pan == 0 ? 'C' : (track.pan < 0 ? 'L${(track.pan.abs() * 100).toInt()}' : 'R${(track.pan * 100).toInt()}'), style: EatsTheme.getDisplayFontStyle(color: EatsTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),
              ],
            ),
          ),


          const SizedBox(height: 16),

          // SoundFont 2 Bank & Preset Selector Card (if SoundFont track)
          _buildSoundFontPresetSelector(context, track),

          // Dynamic Lua Script Parameters (Exposed by Code)
          if ((track.type == TrackType.luaScript || track.luaParams.isNotEmpty) && dawState.compilationResult.params.isNotEmpty) ...[

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EatsTheme.panelBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EatsTheme.accentGreen.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code, color: EatsTheme.accentGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'DYNAMIC SCRIPT PARAMETERS (CODE DRIVEN)',
                        style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 12),
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
                          SizedBox(width: 100, child: Text(paramDef.name, style: EatsTheme.getPrimaryFontStyle(color: EatsTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(
                            child: EatsBitsSlider(
                              value: currentVal,
                              min: paramDef.min,
                              max: paramDef.max,
                              defaultValue: paramDef.defaultValue,
                              label: paramDef.name,
                              activeColor: EatsTheme.accentGreen,
                              onChanged: (val) {
                                dawState.updateLuaParam(paramDef.name, val);
                              },
                            ),
                          ),
                          SizedBox(width: 55, child: Text(currentVal.toStringAsFixed(1), style: EatsTheme.getDisplayFontStyle(color: EatsTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Modular FX Insert Rack
          ModularFxRackWidget(dawState: dawState, track: track),



          const SizedBox(height: 16),

          // Vintage Skeuomorphic Hardware Rack Unit (SILT / PunchBOX Style)
          GrungyRackPanel(
            title: 'Analog Hardware DSP Unit - SILT 808',
            subtitle: 'Real-Time Skeuomorphic Rotary Controls & Nixie Segment Readouts',
            accentColor: EatsTheme.currentPreset == EatsThemePreset.ateTrack
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
                      glowColor: EatsTheme.currentPreset == EatsThemePreset.ateTrack
                          ? const Color(0xFFFF8C00)
                          : track.color,
                    ),
                    GlowingNixieDisplay(
                      label: 'STEREO POSITION',
                      valueText: track.pan == 0
                          ? 'CENTER'
                          : (track.pan < 0 ? 'L${(track.pan.abs() * 100).toInt()}' : 'R${(track.pan * 100).toInt()}'),
                      glowColor: EatsTheme.currentPreset == EatsThemePreset.ateTrack
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
                      accentColor: EatsTheme.currentPreset == EatsThemePreset.ateTrack
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
                      accentColor: EatsTheme.currentPreset == EatsThemePreset.ateTrack
                          ? const Color(0xFFFF8C00)
                          : track.color,
                      onChanged: (val) => dawState.setTrackPan(track, val),
                      formatValue: (v) => v == 0 ? 'CTR' : (v < 0 ? 'L${(v.abs() * 100).toInt()}' : 'R${(v * 100).toInt()}'),
                    ),

                    // Dynamic Script Parameters Card

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
                        accentColor: EatsTheme.accentGreen,
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

