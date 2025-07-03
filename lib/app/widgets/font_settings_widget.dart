import 'package:flutter/material.dart';
import '../pages/font_settings/font_settings_controller.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

class FontSettingsWidget extends StatefulWidget {
  final SettingsRepository settingsRepository;

  const FontSettingsWidget({
    Key? key,
    required this.settingsRepository,
  }) : super(key: key);

  @override
  State<FontSettingsWidget> createState() => _FontSettingsWidgetState();
}

class _FontSettingsWidgetState extends State<FontSettingsWidget> {
  late FontSettingsController _controller;

  final List<String> _fontFamilies = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Source Sans Pro',
    'Raleway',
    'PT Sans',
    'Ubuntu',
  ];

  @override
  void initState() {
    super.initState();
    _controller = FontSettingsController(widget.settingsRepository);
    _controller.initialize();

    // Listen to controller changes
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _controller.currentSettings;

    if (settings == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
                      print('Slider onChanged called with value: $value');
                      _controller.setFontSize(value);
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

            // Font Family Section
            Text(
              'Семейство шрифтов',
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

            // Font Family Dropdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context)
                      .navigationRailTheme
                      .unselectedIconTheme!
                      .color!
                      .withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: settings.fontFamily,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor:
                    Theme.of(context).navigationRailTheme.backgroundColor,
                style: TextStyle(
                  color: Theme.of(context)
                      .navigationRailTheme
                      .unselectedLabelTextStyle!
                      .color,
                  fontSize: 14,
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context)
                      .navigationRailTheme
                      .unselectedIconTheme!
                      .color,
                ),
                items: _fontFamilies.map((String fontFamily) {
                  return DropdownMenuItem<String>(
                    value: fontFamily,
                    child: Text(
                      fontFamily,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  print('Dropdown onChanged called with value: $newValue');
                  if (newValue != null) {
                    _controller.setFontFamily(newValue);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

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
                  fontFamily: settings.fontFamily,
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
  }
}
