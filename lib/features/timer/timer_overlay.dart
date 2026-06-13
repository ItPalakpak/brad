import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../core/theme/theme_notifier.dart';
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

    Overlay.of(context).insert(_entry!);
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
  Offset _position = const Offset(20, 100);
  bool _isExpanded = false;
  String _style = 'bubble'; // 'bubble' | 'bar'

  @override
  void initState() {
    super.initState();
    // Load style from shared preferences if desired
    final prefs = ref.read(sharedPreferencesProvider);
    _style = prefs.getString('timer_style') ?? 'bubble';
  }

  void _toggleStyle() {
    final nextStyle = _style == 'bubble' ? 'bar' : 'bubble';
    ref.read(sharedPreferencesProvider).setString('timer_style', nextStyle);
    setState(() {
      _style = nextStyle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerNotifierProvider);
    final timerNotifier = ref.read(timerNotifierProvider.notifier);
    final tokens = context.tokens;

    // Constrain position to screen bounds
    final size = MediaQuery.of(context).size;
    final double widgetWidth = _isExpanded ? 220.0 : (_style == 'bubble' ? 85.0 : 160.0);
    final double widgetHeight = _isExpanded ? 180.0 : (_style == 'bubble' ? 85.0 : 50.0);

    final constrainedX = _position.dx.clamp(0.0, size.width - widgetWidth);
    final constrainedY = _position.dy.clamp(0.0, size.height - widgetHeight - 80.0);

    return Positioned(
      left: constrainedX,
      top: constrainedY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: _isExpanded
              ? _buildExpandedControls(tokens, timerState, timerNotifier)
              : (_style == 'bubble'
                  ? _buildBubbleWidget(tokens, timerState)
                  : _buildBarWidget(tokens, timerState, timerNotifier)),
        ),
      ),
    );
  }

  // BUBBLE MODE: 80x80 circle showing remaining time
  Widget _buildBubbleWidget(AppColorTokens tokens, TimerState timerState) {
    return OffsetShadowCard(
      shadowOffset: const Offset(2, 2),
      borderWidth: 1.5,
      borderRadius: BorderRadius.zero, // sharp
      padding: EdgeInsets.zero,
      backgroundColor: timerState.isRunning ? tokens.accentSoft : tokens.surface,
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              timerState.isRunning ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 14,
              color: timerState.isRunning ? tokens.accent : tokens.textSubtle,
            ),
            const SizedBox(height: 2),
            Text(
              timerState.formattedTime,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: tokens.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BAR MODE: Slim Pill (150x45)
  Widget _buildBarWidget(AppColorTokens tokens, TimerState timerState, TimerNotifier notifier) {
    return OffsetShadowCard(
      shadowOffset: const Offset(2, 2),
      borderWidth: 1.5,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onTap: () => setState(() => _isExpanded = true),
      child: SizedBox(
        width: 140,
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                if (timerState.isRunning) {
                  notifier.pause();
                } else {
                  notifier.start();
                }
              },
              child: Icon(
                timerState.isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: tokens.accent,
                size: 24,
              ),
            ),
            Text(
              timerState.formattedTime,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: tokens.text,
              ),
            ),
            Icon(Icons.unfold_more_rounded, size: 16, color: tokens.textSubtle),
          ],
        ),
      ),
    );
  }

  // EXPANDED CONTROLS DIALOG
  Widget _buildExpandedControls(AppColorTokens tokens, TimerState timerState, TimerNotifier notifier) {
    return OffsetShadowCard(
      shadowOffset: const Offset(3, 3),
      borderWidth: 1.5,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 190,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SHIFT TIMER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: tokens.textSubtle,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = false),
                  child: Icon(Icons.close_rounded, size: 16, color: tokens.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Time Display
            Center(
              child: Text(
                timerState.formattedTime,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: tokens.text,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Control Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCircle(
                  icon: timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: tokens.accent,
                  onTap: timerState.isRunning ? notifier.pause : notifier.start,
                ),
                _buildActionCircle(
                  icon: Icons.replay_rounded,
                  color: tokens.textSubtle,
                  onTap: notifier.reset,
                ),
                _buildActionCircle(
                  icon: _style == 'bubble' ? Icons.linear_scale_rounded : Icons.circle_outlined,
                  color: tokens.textSubtle,
                  onTap: _toggleStyle,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Add Minutes Row
            Row(
              children: [
                _buildAddMinBtn('+1 Min', () => notifier.addMinutes(1)),
                const SizedBox(width: 4),
                _buildAddMinBtn('+10 Min', () => notifier.addMinutes(10)),
                const SizedBox(width: 4),
                _buildAddMinBtn('Hide', () {
                  TimerOverlayManager.instance.hide();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle({required IconData icon, required Color color, required VoidCallback onTap}) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: tokens.bg,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: tokens.border, width: 1.5),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildAddMinBtn(String label, VoidCallback onTap) {
    final tokens = context.tokens;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: tokens.bg,
            border: Border.all(color: tokens.border, width: 1.0),
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: tokens.text,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
