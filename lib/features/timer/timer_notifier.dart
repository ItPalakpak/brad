import 'dart:async';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/theme_notifier.dart';

part 'timer_notifier.g.dart';

class TimerState {
  final Duration duration;
  final Duration remaining;
  final bool isRunning;

  TimerState({
    required this.duration,
    required this.remaining,
    required this.isRunning,
  });

  String get formattedTime {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    final String hs = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    final String ms = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');

    return '$hs$ms:$ss';
  }

  TimerState copyWith({
    Duration? duration,
    Duration? remaining,
    bool? isRunning,
  }) {
    return TimerState(
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

@riverpod
class TimerNotifier extends _$TimerNotifier {
  Timer? _ticker;

  @override
  TimerState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMins = prefs.getInt('timer_duration_minutes') ?? 30;
    final d = Duration(minutes: savedMins);
    return TimerState(
      duration: d,
      remaining: d,
      isRunning: false,
    );
  }

  void start() {
    if (state.isRunning) return;

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remaining.inSeconds <= 0) {
        pause();
        _onTimerDone();
      } else {
        state = state.copyWith(
          remaining: state.remaining - const Duration(seconds: 1),
        );
      }
    });

    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    pause();
    state = state.copyWith(remaining: state.duration);
  }

  void addMinutes(int minutes) {
    final current = state.remaining;
    final target = current + Duration(minutes: minutes);
    state = state.copyWith(remaining: target);
  }

  void setDuration(int minutes) {
    pause();
    final d = Duration(minutes: minutes);
    state = TimerState(
      duration: d,
      remaining: d,
      isRunning: false,
    );
  }

  Future<void> _onTimerDone() async {
    // Vibrate device
    await HapticFeedback.vibrate();
    
    // Show notification (works completely offline)
    await ref.read(notificationServiceProvider).showTimerDone();
  }
}
