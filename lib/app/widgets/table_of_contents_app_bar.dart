import 'package:flutter/material.dart';
import '../navigation/app_navigator.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';

class TableOfContentsAppBar extends StatelessWidget {
  final String title, name;
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;

  const TableOfContentsAppBar({
    super.key,
    required this.title,
    required this.name,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            return MediaQuery.of(context).orientation == Orientation.portrait
                ? IconButton(
                    onPressed: () async {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: Icon(
                      Icons.menu,
                      size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                      color: Theme.of(context).appBarTheme.iconTheme?.color ??
                          Colors.black,
                    ),
                  )
                : Container();
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(name)),
              );
            },
            child: Text(
              title,
              style: Theme.of(context).appBarTheme.titleTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => AppNavigator.navigateToSearch(
            context,
            regulationRepository: regulationRepository,
            settingsRepository: settingsRepository,
            ttsRepository: ttsRepository,
          ),
        ),
      ],
    );
  }
}
