import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import 'widgets/eatbits_slider.dart';

class ArrangerView extends StatefulWidget {
  final DawState dawState;

  const ArrangerView({super.key, required this.dawState});

  @override
  State<ArrangerView> createState() => _ArrangerViewState();
}

class _ArrangerViewState extends State<ArrangerView> {
  static const double barWidth = 60.0;
  static const double trackRowHeight = 72.0;
  static const int totalBars = 32;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _leftTrackScroll = ScrollController();
  final ScrollController _rightGridScroll = ScrollController();

  bool _isSyncingScroll = false;
  double _moveDragDxAccumulator = 0.0;
  double _resizeDragDxAccumulator = 0.0;

  DateTime? _lastHeaderTapTime;
  int? _lastHeaderTapTrackIdx;
  DateTime? _lastClipTapTime;
  String? _lastClipTapId;

  @override
  void dispose() {
    _horizontalScroll.dispose();
    _leftTrackScroll.dispose();
    _rightGridScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = widget.dawState.activePattern.tracks;
    final double playheadX = (widget.dawState.arrangerStep / 16.0) * barWidth;
    final double loopStartX = widget.dawState.loopStartBar * barWidth;
    final double loopWidth = (widget.dawState.loopEndBar - widget.dawState.loopStartBar) * barWidth;

    return Column(
      children: [
        // Multitrack Grid & Track Panels (Synchronized Scroll)
        Expanded(
          child: Row(
            children: [
              // Left Panel: Vertical Track Control Strips (Synced Scroll)
              SizedBox(
                width: 140,
                child: Column(
                  children: [
                    // Top Left Track Header & Loop Toggle Button
                    Container(
                      height: 24,
                      color: DawTheme.panelHeader,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Text('TRACKS', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          InkWell(
                            onTap: widget.dawState.toggleLoop,
                            child: Tooltip(
                              message: 'Toggle Loop Mode',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 13,
                                    color: widget.dawState.isLooping ? DawTheme.accentGold : DawTheme.textMuted,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.dawState.isLooping ? 'LOOP' : 'OFF',
                                    style: TextStyle(
                                      color: widget.dawState.isLooping ? DawTheme.accentGold : DawTheme.textMuted,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (!_isSyncingScroll && notification is ScrollUpdateNotification) {
                            _isSyncingScroll = true;
                            if (_rightGridScroll.hasClients) {
                              _rightGridScroll.jumpTo(_leftTrackScroll.offset);
                            }
                            _isSyncingScroll = false;
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          controller: _leftTrackScroll,
                          itemCount: tracks.length,
                          itemBuilder: (context, trackIdx) {
                            final track = tracks[trackIdx];
                            final isSelected = trackIdx == widget.dawState.activeTrackIndex;

                            return GestureDetector(
                              onTapDown: (_) {
                                final now = DateTime.now();
                                final isDoubleTap = _lastHeaderTapTrackIdx == trackIdx &&
                                    _lastHeaderTapTime != null &&
                                    now.difference(_lastHeaderTapTime!).inMilliseconds < 300;
                                _lastHeaderTapTime = now;
                                _lastHeaderTapTrackIdx = trackIdx;

                                widget.dawState.activeTrackIndex = trackIdx;
                                if (isDoubleTap) {
                                  // DOUBLE-TAP TRACK HEADER: Navigate to Track Inspector tab
                                  widget.dawState.activeTabIndex = 2; // Track section
                                }
                              },
                              child: Container(
                                height: trackRowHeight,
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected ? DawTheme.controlBackground : DawTheme.panelBackground,
                                  border: Border(
                                    left: BorderSide(color: track.color, width: 4),
                                    bottom: const BorderSide(color: Color(0xFF1B202D), width: 1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      track.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: DawTheme.getPrimaryFontStyle(
                                        color: isSelected ? DawTheme.primaryCyan : DawTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildMuteButton(track),
                                        const SizedBox(width: 4),
                                        _buildSoloButton(track),
                                        const Spacer(),
                                        SizedBox(
                                          width: 50,
                                          height: 20,
                                          child: EatBitsSlider(
                                            value: track.volume,
                                            min: 0.0,
                                            max: 1.5,
                                            defaultValue: 1.0,
                                            label: '${track.name} Volume',
                                            activeColor: track.color,
                                            onChanged: (val) => widget.dawState.setTrackVolume(track, val),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Multitrack Timeline Grid with Top Bar Ruler & Live Playhead
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalBars * barWidth,
                    child: Column(
                      children: [
                        // Top Timeline Bar Ruler (Bar 1, Bar 2 ... Bar 32 with Tap to Jump & Loop Region)
                        GestureDetector(
                          onTapUp: (details) {
                            final double localX = details.localPosition.dx;
                            final int tappedBar = (localX / barWidth).floor();
                            widget.dawState.seekToBar(tappedBar);
                          },
                          onLongPressStart: (details) {
                            final double localX = details.localPosition.dx;
                            final int tappedBar = (localX / barWidth).floor();
                            // Set loop start at tapped bar, end at tapped bar + 4
                            widget.dawState.setLoopPoints(tappedBar, tappedBar + 4);
                          },
                          child: Container(
                            height: 24,
                            color: DawTheme.panelHeader,
                            child: Stack(
                              children: [
                                Row(
                                  children: List.generate(totalBars, (barIdx) {
                                    return Container(
                                      width: barWidth,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        '${barIdx + 1}',
                                        style: DawTheme.getDisplayFontStyle(color: DawTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }),
                                ),

                                // Shaded Loop Region Overlay
                                if (widget.dawState.isLooping)
                                  Positioned(
                                    left: loopStartX,
                                    width: loopWidth,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: DawTheme.accentGold.withOpacity(0.2),
                                        border: Border(
                                          left: BorderSide(color: DawTheme.accentGold, width: 2),
                                          right: BorderSide(color: DawTheme.accentGold, width: 2),
                                        ),
                                      ),
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        'LOOP',
                                        style: TextStyle(
                                          color: DawTheme.accentGold,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Playhead Head Marker Badge
                                Positioned(
                                  left: playheadX - 6,
                                  top: 2,
                                  child: Container(
                                    width: 12,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: DawTheme.primaryCyan,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Icon(Icons.arrow_drop_down, size: 12, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Multitrack Timeline Grid (Synced Scroll, Smooth Clip Drag/Resize & Playhead Line)
                        Expanded(
                          child: Stack(
                            children: [
                              NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (!_isSyncingScroll && notification is ScrollUpdateNotification) {
                                    _isSyncingScroll = true;
                                    if (_leftTrackScroll.hasClients) {
                                      _leftTrackScroll.jumpTo(_rightGridScroll.offset);
                                    }
                                    _isSyncingScroll = false;
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  controller: _rightGridScroll,
                                  itemCount: tracks.length,
                                  itemBuilder: (context, trackIdx) {
                                    final track = tracks[trackIdx];

                                    return Container(
                                      height: trackRowHeight,
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: DawTheme.backgroundDark,
                                        border: const Border(bottom: BorderSide(color: Color(0xFF1B202D), width: 1)),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Bar Grid Lines
                                          Row(
                                            children: List.generate(totalBars, (barIdx) {
                                              return GestureDetector(
                                                onTap: () {
                                                  widget.dawState.activeTrackIndex = trackIdx;
                                                  widget.dawState.addClipToTrack(track, barIdx);
                                                },
                                                child: Container(
                                                  width: barWidth,
                                                  height: trackRowHeight,
                                                  decoration: BoxDecoration(
                                                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),

                                          // Per-track Pattern Clips with Smooth Drag-Move & Edge-Resize
                                          ...track.clips.map((clip) {
                                            return Positioned(
                                              left: clip.startBar * barWidth + 2,
                                              top: 6,
                                              width: (clip.barLength * barWidth) - 4,
                                              height: trackRowHeight - 12,
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTapDown: (_) {
                                                  final now = DateTime.now();
                                                  final isDoubleTap = _lastClipTapId == clip.id &&
                                                      _lastClipTapTime != null &&
                                                      now.difference(_lastClipTapTime!).inMilliseconds < 300;
                                                  _lastClipTapTime = now;
                                                  _lastClipTapId = clip.id;

                                                  widget.dawState.activeTrackIndex = trackIdx;
                                                  widget.dawState.selectClip(clip);
                                                  if (isDoubleTap) {
                                                    // DOUBLE-TAP CLIP: Open clip in Edit section (Piano Roll / Tracker View)
                                                    widget.dawState.openClipInEditor(clip);
                                                  }
                                                },
                                                onHorizontalDragStart: (_) {
                                                  _moveDragDxAccumulator = 0.0;
                                                },
                                                onHorizontalDragUpdate: (details) {
                                                  _moveDragDxAccumulator += details.delta.dx;
                                                  if (_moveDragDxAccumulator.abs() >= barWidth * 0.5) {
                                                    final shiftBars = (_moveDragDxAccumulator / barWidth).round();
                                                    if (shiftBars != 0) {
                                                      setState(() {
                                                        clip.startBar = (clip.startBar + shiftBars).clamp(0, totalBars - clip.barLength);
                                                      });
                                                      _moveDragDxAccumulator -= shiftBars * barWidth;
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: track.color,
                                                    borderRadius: BorderRadius.circular(6),
                                                    boxShadow: [
                                                      BoxShadow(color: track.color.withOpacity(0.4), blurRadius: 6),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  clip.name,
                                                                  style: TextStyle(
                                                                    color: DawTheme.backgroundDark,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 10,
                                                                  ),
                                                                ),
                                                                const Spacer(),
                                                                Icon(Icons.drag_indicator, size: 12, color: DawTheme.backgroundDark),
                                                              ],
                                                            ),
                                                            const Spacer(),
                                                            // Mini note preview bars
                                                            Row(
                                                              children: List.generate(6, (i) {
                                                                return Expanded(
                                                                  child: Container(
                                                                    height: 3,
                                                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                                                    decoration: BoxDecoration(
                                                                      color: DawTheme.backgroundDark.withOpacity(0.6),
                                                                      borderRadius: BorderRadius.circular(1),
                                                                    ),
                                                                  ),
                                                                );
                                                              }),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Right Edge Drag Handle to Resize Clip Length
                                                      GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onHorizontalDragStart: (_) {
                                                          _resizeDragDxAccumulator = 0.0;
                                                        },
                                                        onHorizontalDragUpdate: (details) {
                                                          _resizeDragDxAccumulator += details.delta.dx;
                                                          if (_resizeDragDxAccumulator.abs() >= barWidth * 0.5) {
                                                            final shiftBars = (_resizeDragDxAccumulator / barWidth).round();
                                                            if (shiftBars != 0) {
                                                              setState(() {
                                                                clip.barLength = (clip.barLength + shiftBars).clamp(1, totalBars - clip.startBar);
                                                              });
                                                              _resizeDragDxAccumulator -= shiftBars * barWidth;
                                                            }
                                                          }
                                                        },
                                                        child: Container(
                                                          width: 18,
                                                          height: double.infinity,
                                                          margin: const EdgeInsets.only(left: 4),
                                                          decoration: BoxDecoration(
                                                            color: DawTheme.backgroundDark.withOpacity(0.35),
                                                            borderRadius: const BorderRadius.only(
                                                              topRight: Radius.circular(4),
                                                              bottomRight: Radius.circular(4),
                                                            ),
                                                          ),
                                                          child: Icon(Icons.code, size: 11, color: DawTheme.primaryCyan),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Vertical Song Timeline Playhead Line Across Multitrack Rows
                              Positioned(
                                left: playheadX,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    color: DawTheme.primaryCyan,
                                    boxShadow: [
                                      BoxShadow(color: DawTheme.primaryCyan.withOpacity(0.8), blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMuteButton(TrackChannel track) {
    return GestureDetector(
      onTap: () => widget.dawState.toggleMute(track),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: track.isMuted ? DawTheme.muteColor : DawTheme.panelHeader,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('M', style: TextStyle(color: track.isMuted ? Colors.white : DawTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSoloButton(TrackChannel track) {
    return GestureDetector(
      onTap: () => widget.dawState.toggleSolo(track),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: track.isSoloed ? DawTheme.soloColor : DawTheme.panelHeader,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('S', style: TextStyle(color: track.isSoloed ? Colors.black : DawTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
