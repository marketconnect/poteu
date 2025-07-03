import 'package:flutter/material.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../main.dart';

class SimpleFontSettingsWidget extends StatefulWidget {
  final SettingsRepository settingsRepository;

  const SimpleFontSettingsWidget({
    Key? key,
    required this.settingsRepository,
  }) : super(key: key);

  @override
  State<SimpleFontSettingsWidget> createState() =>
      _SimpleFontSettingsWidgetState();
}

class _SimpleFontSettingsWidgetState extends State<SimpleFontSettingsWidget> {
  Future<void> _updateFontSize(double fontSize) async {
    try {
      print('SimpleFontSettingsWidget: Updating font size to $fontSize');
      await widget.settingsRepository.setFontSize(fontSize);

      final currentSettings = FontManager().currentSettings;
      final newSettings = currentSettings.copyWith(fontSize: fontSize);

      // Уведомляем FontManager
      FontManager().updateSettings(newSettings);
      print('SimpleFontSettingsWidget: Font size updated successfully');
    } catch (e) {
      print('SimpleFontSettingsWidget: Error updating font size: $e');
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
        print(
            'SimpleFontSettingsWidget: Building with fontSize=${settings.fontSize}');

        return Container(
          color: Theme.of(context).navigationRailTheme.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Font Size Section
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
                            ?.withOpacity(0.3),
                        onChanged: (value) {
                          print(
                              'SimpleFontSettingsWidget: Slider changed to $value');
                          _updateFontSize(value);
                        },
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
                const SizedBox(height: 24),

                // Preview Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .navigationRailTheme
                        .indicatorColor
                        ?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .navigationRailTheme
                          .unselectedIconTheme!
                          .color!
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Пример текста для предварительного просмотра',
                    style: TextStyle(
                      fontSize: settings.fontSize,
                      color: Theme.of(context)
                          .navigationRailTheme
                          .unselectedLabelTextStyle!
                          .color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
