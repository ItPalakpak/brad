import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/themes/all_themes.dart';
import '../../core/theme/theme_notifier.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/brand_logo.dart';

class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final notifier = ref.read(themeNotifierProvider.notifier);
    final tokens = context.tokens;

    final List<String> themesList = [
      'pure-bold',
      'techy',
      'friendly',
      'corporate',
      'playful',
      'trailblazer',
      'monochrome',
      'rider-green',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector: Light vs Dark
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Switch(
              value: themeState.isDark,
              onChanged: (_) => notifier.toggleMode(),
              activeThumbColor: tokens.accent,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Brand Preview Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border.all(color: tokens.border, width: 1.5),
            borderRadius: BorderRadius.zero,
            boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'BRAND PREVIEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tokens.textSubtle,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(type: BrandLogoType.icon, height: 48),
                      const SizedBox(height: 6),
                      Text(
                        'Icon',
                        style: TextStyle(fontSize: 10, color: tokens.textSubtle, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(type: BrandLogoType.mark, height: 48),
                      const SizedBox(height: 6),
                      Text(
                        'Mark',
                        style: TextStyle(fontSize: 10, color: tokens.textSubtle, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(type: BrandLogoType.wordmark, height: 22),
                      const SizedBox(height: 16),
                      Text(
                        'Wordmark',
                        style: TextStyle(fontSize: 10, color: tokens.textSubtle, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grid of 8 theme swatches
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: themesList.length,
          itemBuilder: (context, index) {
            final id = themesList[index];
            final name = AppThemes.getThemeName(id);
            final t = AppThemes.getTokens(id, themeState.isDark);
            final isSelected = themeState.themeId == id;

            return OffsetShadowCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: t.bg,
              shadowColor: isSelected ? tokens.accent : tokens.border,
              borderWidth: isSelected ? 2.0 : 1.5,
              onTap: () => notifier.setTheme(id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: t.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: tokens.accent,
                        ),
                    ],
                  ),
                  
                  // Swatch Colors Row
                  Row(
                    children: [
                      _buildColorDot(t.surface, t.border),
                      const SizedBox(width: 4),
                      _buildColorDot(t.primary, t.border),
                      const SizedBox(width: 4),
                      _buildColorDot(t.accent, t.border),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorDot(Color color, Color border) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.0),
      ),
    );
  }
}
