import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../main.dart';

class FontSizeSettingsWidget extends StatefulWidget {
  final SettingsRepository settingsRepository;

  const FontSizeSettingsWidget({
    Key? key,
    required this.settingsRepository,
  }) : super(key: key);

  @override
  State<FontSizeSettingsWidget> createState() => _FontSizeSettingsWidgetState();
}

class _FontSizeSettingsWidgetState extends State<FontSizeSettingsWidget> {
  Future<void> _updateFontSize(double fontSize) async {
    try {
      await widget.settingsRepository.setFontSize(fontSize);
      final currentSettings = FontManager().currentSettings;
      final newSettings = currentSettings.copyWith(fontSize: fontSize);
      FontManager().updateSettings(newSettings);
    } catch (e) {
      dev.log('Error updating font size: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Settings>(
      stream: FontManager().fontStream,
      initialData: FontManager().currentSettings,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = snapshot.data!;

        return Container(
          color: Theme.of(context).navigationRailTheme.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Размер шрифта',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .navigationRailTheme
                        .unselectedLabelTextStyle!
                        .color,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${settings.fontSize.round()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .navigationRailTheme
                            .unselectedLabelTextStyle!
                            .color,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: settings.fontSize,
                        min: 12.0,
                        max: 28.0,
                        divisions: 16,
                        activeColor: Theme.of(context)
                            .navigationRailTheme
                            .selectedIconTheme!
                            .color,
                        inactiveColor: Theme.of(context)
                            .navigationRailTheme
                            .unselectedIconTheme!
                            .color
                            ?.withValues(alpha: 0.3),
                        onChanged: _updateFontSize,
                      ),
                    ),
                    Text(
                      'Aа',
                      style: TextStyle(
                        fontSize: settings.fontSize,
                        color: Theme.of(context)
                            .navigationRailTheme
                            .unselectedLabelTextStyle!
                            .color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
