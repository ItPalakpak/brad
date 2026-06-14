import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'timer_notifier.dart';

class TimerOverlayManager {
  static final TimerOverlayManager instance = TimerOverlayManager._();
  TimerOverlayManager._();

  OverlayEntry? _entry;
  bool get isShown => _entry != null;

  void show(BuildContext context, WidgetRef ref) {
    if (_entry != null) return;
    
    _entry = OverlayEntry(
      builder: (context) {
        return const DraggableTimerOverlay();
      },
    );

    final rootOverlay = Navigator.of(context, rootNavigator: true).overlay;
    if (rootOverlay != null) {
      rootOverlay.insert(_entry!);
    } else {
      Overlay.of(context).insert(_entry!);
    }
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class DraggableTimerOverlay extends ConsumerStatefulWidget {
  const DraggableTimerOverlay({super.key});

  @override
  ConsumerState<DraggableTimerOverlay> createState() => _DraggableTimerOverlayState();
}

class _DraggableTimerOverlayState extends ConsumerState<DraggableTimerOverlay> {
  bool _pickerOpenA = false;
  bool _pickerOpenB = false;
  final TextEditingController _customControllerA = TextEditingController();
  final TextEditingController _customControllerB = TextEditingController();

  @override
  void dispose() {
    _customControllerA.dispose();
    _customControllerB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState1 = ref.watch(timerNotifierProvider);
    final notifier1 = ref.read(timerNotifierProvider.notifier);

    final timerState2 = ref.watch(bottomTimerNotifierProvider);
    final notifier2 = ref.read(bottomTimerNotifierProvider.notifier);

    final tokens = context.tokens;

    return Positioned.fill(
      child: Scaffold(
        backgroundColor: Colors.black, // Dark clock display background
        body: Stack(
          children: [
            // Body Content
            SafeArea(
              child: Column(
                children: [
                  // Top Timer Section
                  Expanded(
                    child: _buildTimerPanel(
                      title: 'TIMER A - PRIMARY SHIFT',
                      state: timerState1,
                      notifier: notifier1,
                      activeColor: tokens.accent,
                      inactiveColor: tokens.accent.withValues(alpha: 0.05),
                      tokens: tokens,
                      pickerOpen: _pickerOpenA,
                      customController: _customControllerA,
                      onTogglePicker: () => setState(() => _pickerOpenA = !_pickerOpenA),
                    ),
                  ),
                  
                  // Clean thin divider
                  Container(
                    height: 1,
                    color: tokens.border.withValues(alpha: 0.15),
                  ),
                  
                  // Bottom Timer Section
                  Expanded(
                    child: _buildTimerPanel(
                      title: 'TIMER B - SECONDARY SHIFT',
                      state: timerState2,
                      notifier: notifier2,
                      activeColor: AppStatusColors.warning,
                      inactiveColor: AppStatusColors.warning.withValues(alpha: 0.05),
                      tokens: tokens,
                      pickerOpen: _pickerOpenB,
                      customController: _customControllerB,
                      onTogglePicker: () => setState(() => _pickerOpenB = !_pickerOpenB),
                    ),
                  ),
                ],
              ),
            ),
            
            // Close Button in top right
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 28, color: Colors.white),
                  onPressed: () {
                    TimerOverlayManager.instance.hide();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerPanel({
    required String title,
    required TimerState state,
    required dynamic notifier, // timerNotifier or bottomTimerNotifier
    required Color activeColor,
    required Color inactiveColor,
    required AppColorTokens tokens,
    required bool pickerOpen,
    required TextEditingController customController,
    required VoidCallback onTogglePicker,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Increase relative width for larger digits
        final double digitWidth = (width - 80) / 6;
        final double digitHeight = digitWidth * 1.65;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: tokens.textSubtle.withValues(alpha: 0.6),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              
              // Seven Segment Display (Clean & Floating directly on the black background!)
              SevenSegmentTimeDisplay(
                remaining: state.remaining,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                digitWidth: digitWidth.clamp(35.0, 65.0),
                digitHeight: digitHeight.clamp(60.0, 110.0),
              ),
              const SizedBox(height: 20),
              
              // Control Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPanelBtn(
                    icon: state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    label: state.isRunning ? 'PAUSE' : 'START',
                    color: activeColor,
                    onTap: state.isRunning ? notifier.pause : notifier.start,
                  ),
                  const SizedBox(width: 16),
                  _buildPanelBtn(
                    icon: Icons.replay_rounded,
                    label: 'RESET',
                    color: tokens.textSubtle,
                    onTap: notifier.reset,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Action adjustment chips & Preset selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionChip(label: '+1 Min', onTap: () => notifier.addMinutes(1), tokens: tokens),
                  const SizedBox(width: 8),
                  _buildActionChip(label: '+5 Min', onTap: () => notifier.addMinutes(5), tokens: tokens),
                  const SizedBox(width: 8),
                  _buildActionChip(label: '+10 Min', onTap: () => notifier.addMinutes(10), tokens: tokens),
                  const SizedBox(width: 16),
                  
                  // Duration Presets Combo Selector
                  _buildActionChip(
                    label: _formatDurationLabel(state.duration.inMinutes),
                    onTap: onTogglePicker,
                    tokens: tokens,
                  ),
                ],
              ),

              // Inline Duration Picker (expands below chips)
              if (pickerOpen) ...[
                const SizedBox(height: 12),
                _buildInlineDurationPicker(
                  currentMinutes: state.duration.inMinutes,
                  customController: customController,
                  onSelected: (val) {
                    notifier.setDuration(val);
                    onTogglePicker();
                  },
                  tokens: tokens,
                ),
              ],
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildPanelBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border, width: 2.0),
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: tokens.shadowColor,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: tokens.text,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required VoidCallback onTap,
    required AppColorTokens tokens,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: tokens.text,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  String _formatDurationLabel(int minutes) {
    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 Hour' : '$hours Hours';
    }
    return '$minutes Mins';
  }

  Widget _buildInlineDurationPicker({
    required int currentMinutes,
    required TextEditingController customController,
    required ValueChanged<int> onSelected,
    required AppColorTokens tokens,
  }) {
    const presets = [5, 15, 30, 45, 60, 120];

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha: 0.1),
        border: Border.all(color: tokens.border.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preset duration chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: presets.map((mins) {
              final isActive = currentMinutes == mins;
              return GestureDetector(
                onTap: () => onSelected(mins),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? tokens.accentSoft : Colors.transparent,
                    border: Border.all(
                      color: isActive ? tokens.accent : tokens.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    _formatDurationLabel(mins),
                    style: TextStyle(
                      color: isActive ? tokens.accent : tokens.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Custom duration input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.border, width: 1.5),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: tokens.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Custom mins',
                      hintStyle: TextStyle(color: tokens.textSubtle, fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final parsed = int.tryParse(customController.text.trim());
                  if (parsed != null && parsed > 0) {
                    onSelected(parsed);
                    customController.clear();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.accent,
                    border: Border.all(color: tokens.border, width: 1.5),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    'SET',
                    style: TextStyle(
                      color: tokens.surface,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SevenSegmentTimeDisplay extends StatelessWidget {
  final Duration remaining;
  final Color activeColor;
  final Color inactiveColor;
  final double digitWidth;
  final double digitHeight;

  const SevenSegmentTimeDisplay({
    super.key,
    required this.remaining,
    required this.activeColor,
    required this.inactiveColor,
    this.digitWidth = 45,
    this.digitHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    final showHours = hours > 0;

    final List<int> digits = [];
    if (showHours) {
      digits.add(hours ~/ 10);
      digits.add(hours % 10);
      digits.add(-1); // Colon indicator
    }
    digits.add(minutes ~/ 10);
    digits.add(minutes % 10);
    digits.add(-1); // Colon indicator
    digits.add(seconds ~/ 10);
    digits.add(seconds % 10);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((val) {
        if (val == -1) {
          // Colon
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColonDot(),
                const SizedBox(height: 12),
                _buildColonDot(),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SevenSegmentDigit(
              digit: val,
              width: digitWidth,
              height: digitHeight,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildColonDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: activeColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(1.0),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.5),
            blurRadius: 4,
          )
        ],
      ),
    );
  }
}

class SevenSegmentDigit extends StatelessWidget {
  final int digit;
  final double width;
  final double height;
  final Color activeColor;
  final Color inactiveColor;

  const SevenSegmentDigit({
    super.key,
    required this.digit,
    this.width = 60,
    this.height = 100,
    required this.activeColor,
    required this.inactiveColor,
  });

  // Segments: A (top), B (top-right), C (bottom-right), D (bottom), E (bottom-left), F (top-left), G (middle)
  static const Map<int, List<bool>> _digitSegments = {
    //      A     B     C     D     E     F     G
    0: [ true,  true,  true,  true,  true,  true, false],
    1: [false,  true,  true, false, false, false, false],
    2: [ true,  true, false,  true,  true, false,  true],
    3: [ true,  true,  true,  true, false, false,  true],
    4: [false,  true,  true, false, false,  true,  true],
    5: [ true, false,  true,  true, false,  true,  true],
    6: [ true, false,  true,  true,  true,  true,  true],
    7: [ true,  true,  true, false, false, false, false],
    8: [ true,  true,  true,  true,  true,  true,  true],
    9: [ true,  true,  true,  true, false,  true,  true],
  };

  @override
  Widget build(BuildContext context) {
    final segments = _digitSegments[digit] ?? List.filled(7, false);
    final thickness = width * 0.13; // thickness of segments relative to width
    final halfThickness = thickness / 2;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Segment A (Top)
          Positioned(
            top: 0,
            left: halfThickness,
            right: halfThickness,
            height: thickness,
            child: _SegmentBar(on: segments[0], activeColor: activeColor, inactiveColor: inactiveColor, isHorizontal: true),
          ),
          // Segment F (Top-Left)
          Positioned(
            top: halfThickness,
            left: 0,
            width: thickness,
            height: (height / 2) - halfThickness,
            child: _SegmentBar(on: segments[5], activeColor: activeColor, inactiveColor: inactiveColor, isHorizontal: false),
          ),
          // Segment B (Top-Right)
          Positioned(
            top: halfThickness,
            right: 0,
            width: thickness,
            height: (height / 2) - halfThickness,
            child: _SegmentBar(on: segments[1], activeColor: activeColor, inactiveColor: inactiveColor, isHorizontal: false),
          ),
          // Segment G (Middle)
          Positioned(
            top: (height / 2) - (thickness / 2),
            left: halfThickness,
            right: halfThickness,
            height: thickness,
            child: _SegmentBar(on: segments[6], activeColor: activeColor, inactiveColor: inactiveColor, isHorizontal: true),
          ),
          // Segment E (Bottom-Left)
          Positioned(
            top: height / 2,
            left: 0,
            width: thickness,
            height: (height / 2) - halfThickness,
            child: _SegmentBar(on: segments[4], activeColor: activeColor, inactiveColor: inactiveColor, isHorizontal: false),
          ),
          // Segment C (Bottom-Right)
          Positioned(
            top: height / 2,
            right: 0,
            width: thickness,
            height: (height / 2) - halfThickness,
            child: _SegmentBar(on: segments[2], activeColor: activeColor, inactiveColor: inactiveColor, isHorizontal: false),
          ),
          // Segment D (Bottom)
          Positioned(
            bottom: 0,
            left: halfThickness,
            right: halfThickness,
            height: thickness,
            child: _SegmentBar(on: segments[3], activeColor: activeColor, inactiveColor: inactiveColor, isHorizontal: true),
          ),
        ],
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  final bool on;
  final Color activeColor;
  final Color inactiveColor;
  final bool isHorizontal;

  const _SegmentBar({
    required this.on,
    required this.activeColor,
    required this.inactiveColor,
    required this.isHorizontal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: on ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(1.5),
        border: Border.all(
          color: on ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
          width: 0.5,
        ),
        boxShadow: on
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.35),
                  blurRadius: 3.5,
                  spreadRadius: 0.5,
                )
              ]
            : null,
      ),
    );
  }
}
