/// Simple mock repositories for basic UI testing
class SimpleMockRepositories {
  final SimpleRegulationRepository regulationRepository;
  final SimpleSettingsRepository settingsRepository;
  final SimpleTTSRepository ttsRepository;
  final SimpleNotesRepository notesRepository;

  SimpleMockRepositories()
      : regulationRepository = SimpleRegulationRepository(),
        settingsRepository = SimpleSettingsRepository(),
        ttsRepository = SimpleTTSRepository(),
        notesRepository = SimpleNotesRepository();
}

/// Basic mock regulation repository for testing UI
class SimpleRegulationRepository {
  // Empty implementation - just for UI testing
}

/// Basic mock settings repository for testing UI
class SimpleSettingsRepository {
  // Empty implementation - just for UI testing
}

/// Basic mock TTS repository for testing UI
class SimpleTTSRepository {
  // Empty implementation - just for UI testing
}

/// Basic mock notes repository for testing UI
class SimpleNotesRepository {
  // Empty implementation - just for UI testing
}
