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

// BUG-16 FIX: Both timer notifiers now persist start time + duration to SharedPreferences.
// On app resume/restart, elapsed time is calculated from the persisted start time,
// so the timer survives app kills and background eviction.

@riverpod
class TimerNotifier extends _$TimerNotifier {
  Timer? _ticker;
  static const _prefKeyStartTime = 'timer_start_epoch_ms';
  static const _prefKeyDurationSecs = 'timer_total_duration_secs';

  @override
  TimerState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMins = prefs.getInt('timer_duration_minutes') ?? 30;
    final d = Duration(minutes: savedMins);

    // Restore persisted timer if it was running when app was killed
    final persistedStart = prefs.getInt(_prefKeyStartTime);
    final persistedDuration = prefs.getInt(_prefKeyDurationSecs);

    if (persistedStart != null && persistedDuration != null) {
      final startTime = DateTime.fromMillisecondsSinceEpoch(persistedStart);
      final totalDuration = Duration(seconds: persistedDuration);
      final elapsed = DateTime.now().difference(startTime);
      final remaining = totalDuration - elapsed;

      if (remaining.inSeconds > 0) {
        // Timer is still active — resume it
        Future.microtask(() => _resumeTicker());
        return TimerState(
          duration: totalDuration,
          remaining: remaining,
          isRunning: true,
        );
      } else {
        // Timer expired while app was dead — fire notification and clear
        Future.microtask(() => _onTimerDone());
        _clearPersistedTimer();
        return TimerState(duration: d, remaining: Duration.zero, isRunning: false);
      }
    }

    return TimerState(duration: d, remaining: d, isRunning: false);
  }

  void _resumeTicker() {
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
  }

  void start() {
    if (state.isRunning) return;

    // Persist start time so timer survives app kill
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_prefKeyStartTime, DateTime.now().millisecondsSinceEpoch);
    prefs.setInt(_prefKeyDurationSecs, state.remaining.inSeconds);

    _resumeTicker();
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    _clearPersistedTimer();
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

    // Update persisted duration if timer is running
    if (state.isRunning) {
      final prefs = ref.read(sharedPreferencesProvider);
      final startMs = prefs.getInt(_prefKeyStartTime);
      if (startMs != null) {
        final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startMs));
        prefs.setInt(_prefKeyDurationSecs, (elapsed + target).inSeconds);
      }
    }
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

  void _clearPersistedTimer() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove(_prefKeyStartTime);
    prefs.remove(_prefKeyDurationSecs);
  }

  Future<void> _onTimerDone() async {
    _clearPersistedTimer();
    // Vibrate device
    await HapticFeedback.vibrate();
    
    // Show notification (works completely offline)
    await ref.read(notificationServiceProvider).showTimerDone();
  }
}

@riverpod
class BottomTimerNotifier extends _$BottomTimerNotifier {
  Timer? _ticker;
  static const _prefKeyStartTime = 'btimer_start_epoch_ms';
  static const _prefKeyDurationSecs = 'btimer_total_duration_secs';

  @override
  TimerState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMins = prefs.getInt('timer_duration_minutes_bottom') ?? 30;
    final d = Duration(minutes: savedMins);

    // Restore persisted timer if it was running when app was killed
    final persistedStart = prefs.getInt(_prefKeyStartTime);
    final persistedDuration = prefs.getInt(_prefKeyDurationSecs);

    if (persistedStart != null && persistedDuration != null) {
      final startTime = DateTime.fromMillisecondsSinceEpoch(persistedStart);
      final totalDuration = Duration(seconds: persistedDuration);
      final elapsed = DateTime.now().difference(startTime);
      final remaining = totalDuration - elapsed;

      if (remaining.inSeconds > 0) {
        Future.microtask(() => _resumeTicker());
        return TimerState(
          duration: totalDuration,
          remaining: remaining,
          isRunning: true,
        );
      } else {
        Future.microtask(() => _onTimerDone());
        _clearPersistedTimer();
        return TimerState(duration: d, remaining: Duration.zero, isRunning: false);
      }
    }

    return TimerState(duration: d, remaining: d, isRunning: false);
  }

  void _resumeTicker() {
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
  }

  void start() {
    if (state.isRunning) return;

    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_prefKeyStartTime, DateTime.now().millisecondsSinceEpoch);
    prefs.setInt(_prefKeyDurationSecs, state.remaining.inSeconds);

    _resumeTicker();
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    _clearPersistedTimer();
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

    if (state.isRunning) {
      final prefs = ref.read(sharedPreferencesProvider);
      final startMs = prefs.getInt(_prefKeyStartTime);
      if (startMs != null) {
        final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startMs));
        prefs.setInt(_prefKeyDurationSecs, (elapsed + target).inSeconds);
      }
    }
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

  void _clearPersistedTimer() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove(_prefKeyStartTime);
    prefs.remove(_prefKeyDurationSecs);
  }

  Future<void> _onTimerDone() async {
    _clearPersistedTimer();
    // Vibrate device
    await HapticFeedback.vibrate();
    
    // Show notification (works completely offline)
    await ref.read(notificationServiceProvider).showTimerDone();
  }
}
