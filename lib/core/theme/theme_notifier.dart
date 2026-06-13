import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_notifier.g.dart';

class ThemeState {
  final String themeId;
  final bool isDark;

  ThemeState({required this.themeId, required this.isDark});

  ThemeState copyWith({String? themeId, bool? isDark}) {
    return ThemeState(
      themeId: themeId ?? this.themeId,
      isDark: isDark ?? this.isDark,
    );
  }
}

@riverpod
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError();
}

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ThemeState(
      themeId: prefs.getString('theme_id') ?? 'rider-green', // rider-green default dark
      isDark: prefs.getBool('theme_is_dark') ?? true, // default to dark mode
    );
  }

  Future<void> setTheme(String id) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('theme_id', id);
    state = state.copyWith(themeId: id);
  }

  Future<void> toggleMode() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = !state.isDark;
    await prefs.setBool('theme_is_dark', next);
    state = state.copyWith(isDark: next);
  }
}
