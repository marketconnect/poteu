import 'package:flutter/material.dart';
import '../table_of_contents/table_of_contents_page.dart';
import '../../../data/repositories/static_regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';

class MainView extends StatelessWidget {
  final StaticRegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;

  const MainView({
    Key? key,
    required this.regulationRepository,
    required this.settingsRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simply return the table of contents page
    return TableOfContentsPage(
      regulationRepository: regulationRepository,
      settingsRepository: settingsRepository,
    );
  }
}
