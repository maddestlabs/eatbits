import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import 'widgets/lcd_display_widget.dart';
import 'widgets/skeuomorphic_hardware_button.dart';
import 'widgets/skeuomorphic_hardware_knob.dart';
import 'widgets/skeuomorphic_hardware_slider.dart';
import 'widgets/stereo_meter_widget.dart';

class MixerView extends StatefulWidget {
  final DawState dawState;

  const MixerView({super.key, required this.dawState});

  @override
  State<MixerView> createState() => _MixerViewState();
}

class _MixerViewState extends State<MixerView> {
  DateTime? _lastTapTime;
  int? _lastTapTrackIdx;

  @override
  Widget build(BuildContext context) {
    final pattern = widget.dawState.activePattern;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Master Channel Strip
          _buildMasterChannelStrip(widget.dawState),
          VerticalDivider(color: DawTheme.panelHeader, width: 24, thickness: 1.5),

          // Individual Track Strips
          ...List.generate(pattern.tracks.length, (tIdx) {
            return _buildTrackStrip(context, widget.dawState, pattern.tracks[tIdx], tIdx);
          }),
        ],
      ),
    );
  }

  Widget _buildMasterChannelStrip(DawState dawState) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DawTheme.panelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DawTheme.primaryCyan.withOpacity(0.6), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          // Top Backlit LCD Screen
          LcdDisplayWidget(
            title: 'MASTER',
            leftText: 'st-out',
            rightText: '${(dawState.masterVolume * 100).toInt()}%',
            width: 124,
            height: 38,
          ),
          const SizedBox(height: 8),

          // Dual Master Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tooltip(
                message: 'Master Balance',
                child: SkeuomorphicHardwareKnob(
                  value: 0.0,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  size: 36.0,
                  accentColor: DawTheme.primaryCyan,
                  onChanged: (_) {},
                  formatValue: (v) => 'C',
                ),
              ),
              Tooltip(
                message: 'Master Gain',
                child: SkeuomorphicHardwareKnob(
                  value: dawState.masterVolume,
                  min: 0.0,
                  max: 1.5,
                  defaultValue: 0.85,
                  size: 36.0,
                  accentColor: DawTheme.primaryCyan,
                  onChanged: (val) => dawState.setMasterVolume(val),
                  formatValue: (v) => '${(v * 100).toInt()}%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Fader + Inset Glass Meter on Right
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fader Slider on Left (with level scale markings)
                Expanded(
                  child: SkeuomorphicHardwareSlider(
                    value: dawState.masterVolume,
                    min: 0.0,
                    max: 1.5,
                    defaultValue: 0.85,
                    label: 'Master Volume',
                    activeColor: DawTheme.primaryCyan,
                    orientation: Axis.vertical,
                    length: 160.0,
                    showLevelMarkings: true,
                    onChanged: (val) => dawState.setMasterVolume(val),
                  ),
                ),
                const SizedBox(width: 4),

                // Glass Meter Readout on Right
                StereoMeterWidget(
                  leftLevel: dawState.audioEngine.leftPeak,
                  rightLevel: dawState.audioEngine.rightPeak,
                  accentColor: DawTheme.primaryCyan,
                  width: 38.0,
                  height: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackStrip(BuildContext context, DawState dawState, TrackChannel track, int trackIdx) {
    final isSelected = trackIdx == dawState.activeTrackIndex;
    final leftPeak = dawState.audioEngine.getTrackLeftPeak(track.id);
    final rightPeak = dawState.audioEngine.getTrackRightPeak(track.id);

    return GestureDetector(
      onTapDown: (_) {
        final now = DateTime.now();
        final isDoubleTap = _lastTapTrackIdx == trackIdx &&
            _lastTapTime != null &&
            now.difference(_lastTapTime!).inMilliseconds < 300;
        _lastTapTime = now;
        _lastTapTrackIdx = trackIdx;

        dawState.activeTrackIndex = trackIdx;
        if (isDoubleTap) {
          dawState.activeTabIndex = 2; // Switch to TRACK section
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? DawTheme.controlBackground : DawTheme.panelBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? track.color : Colors.transparent, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            // Top Backlit LCD Screen
            LcdDisplayWidget(
              title: '${trackIdx + 1}  ${track.name.toUpperCase()}',
              leftText: track.pan == 0 ? 'center' : (track.pan < 0 ? 'L${(track.pan.abs() * 100).toInt()}' : 'R${(track.pan * 100).toInt()}'),
              rightText: '${(track.volume * 100).toInt()}%',
              width: 124,
              height: 38,
            ),

            const SizedBox(height: 8),

            // Hardware Knobs Row (Pan knob + Cutoff knob)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Tooltip(
                  message: 'Pan (${track.pan})',
                  child: SkeuomorphicHardwareKnob(
                    value: track.pan,
                    min: -1.0,
                    max: 1.0,
                    defaultValue: 0.0,
                    size: 34.0,
                    accentColor: track.color,
                    onChanged: (val) => dawState.setTrackPan(track, val),
                    formatValue: (v) => v == 0 ? 'C' : (v < 0 ? 'L${(v.abs() * 100).toInt()}' : 'R${(v * 100).toInt()}'),
                  ),
                ),
                Tooltip(
                  message: 'Cutoff (${track.cutoff.toInt()} Hz)',
                  child: SkeuomorphicHardwareKnob(
                    value: track.cutoff,
                    min: 200.0,
                    max: 10000.0,
                    defaultValue: 3000.0,
                    size: 34.0,
                    accentColor: DawTheme.accentGold,
                    onChanged: (val) {
                      track.cutoff = val;
                      dawState.notifyState();
                    },
                    formatValue: (v) => '${(v / 1000).toStringAsFixed(1)}k',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Fader (Left) + Glass Meter (Right) + Mechanical Buttons Column (Far Right)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vertical Console Fader with level scale markings
                  Expanded(
                    child: SkeuomorphicHardwareSlider(
                      value: track.volume,
                      min: 0.0,
                      max: 1.5,
                      defaultValue: 1.0,
                      label: '${track.name} Volume',
                      activeColor: track.color,
                      orientation: Axis.vertical,
                      length: 160.0,
                      showLevelMarkings: true,
                      onChanged: (val) => dawState.setTrackVolume(track, val),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Inset Glass-Encased Stereo Meter on RIGHT side of fader
                  StereoMeterWidget(
                    leftLevel: leftPeak,
                    rightLevel: rightPeak,
                    accentColor: track.color,
                    width: 38.0,
                    height: double.infinity,
                  ),
                  const SizedBox(width: 5),

                  // Compact Vertical Hardware Button Column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SkeuomorphicHardwareButton(
                        label: 'm',
                        isActive: track.isMuted,
                        activeColor: DawTheme.muteColor,
                        onTap: () => dawState.toggleMute(track),
                        height: 26,
                        width: 26,
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      SkeuomorphicHardwareButton(
                        label: 's',
                        isActive: track.isSoloed,
                        activeColor: DawTheme.soloColor,
                        onTap: () => dawState.toggleSolo(track),
                        height: 26,
                        width: 26,
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 6),
                      SkeuomorphicHardwareButton(
                        label: 'FX',
                        isActive: track.fxRack.any((f) => f.enabled),
                        activeColor: DawTheme.primaryCyan,
                        onTap: () => _showFXRackDialog(context, dawState, track),
                        height: 26,
                        width: 26,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFXRackDialog(BuildContext context, DawState dawState, TrackChannel track) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DawTheme.panelBackground,
          title: Text('FX INSERT RACK: ${track.name}', style: TextStyle(color: DawTheme.primaryCyan)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Bitcrusher 8-Bit', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text('Sample reduction & bit depth', style: TextStyle(color: DawTheme.textMuted, fontSize: 10)),
                  trailing: Switch(
                    value: track.fxRack.any((f) => f.name == 'Bitcrusher'),
                    onChanged: (val) => dawState.toggleBitcrusher(track, val),
                  ),
                ),
                ListTile(
                  title: const Text('Tube Distortion', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text('Soft clipping warmth', style: TextStyle(color: DawTheme.textMuted, fontSize: 10)),
                  trailing: Switch(
                    value: track.fxRack.any((f) => f.name == 'TubeDistortion'),
                    onChanged: (val) => dawState.toggleDistortion(track, val),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: TextStyle(color: DawTheme.primaryCyan)),
            ),
          ],
        );
      },
    );
  }
}
