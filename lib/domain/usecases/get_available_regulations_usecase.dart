import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'dart:developer' as dev;
import '../entities/regulation.dart';
import '../repositories/cloud_regulation_repository.dart';
import '../repositories/regulation_repository.dart';

class GetAvailableRegulationsUseCase extends UseCase<List<Regulation>, void> {
  final CloudRegulationRepository _cloudRepository;
  final RegulationRepository _localRepository;

  GetAvailableRegulationsUseCase(this._cloudRepository, this._localRepository);

  @override
  Future<Stream<List<Regulation>>> buildUseCaseStream(void params) async {
    final controller = StreamController<List<Regulation>>();
    try {
      // 1. Get server regulations list
      final serverRegulations =
          await _cloudRepository.getAvailableRegulations();
      dev.log('Fetched ${serverRegulations.length} regulations from server.');

      // 2. Get local regulations metadata
      final localRegulations =
          await _localRepository.getLocalRulesWithMetadata();
      final localRegulationsMap = {for (var r in localRegulations) r.id: r};
      dev.log('Fetched ${localRegulations.length} regulations from local DB.');

      // 3. Filter for only DOWNLOADED documents and compare versions
      final downloadedServerRegulations =
          serverRegulations.where((r) => r.isDownloaded).toList();
      dev.log(
          'Found ${downloadedServerRegulations.length} downloaded regulations to check for updates.');

      for (final serverReg in downloadedServerRegulations) {
        final localReg = localRegulationsMap[serverReg.id];

        dev.log(
            '[SYNC] Comparing downloaded document ID ${serverReg.id} ("${serverReg.title}")');
        dev.log('[SYNC]   Local change_date: ${localReg?.changeDate}');
        dev.log('[SYNC]   Server change_date: ${serverReg.changeDate}');

        if (localReg?.changeDate != serverReg.changeDate) {
          dev.log(
              '[SYNC]   -> MISMATCH DETECTED. Deleting and re-downloading document ID ${serverReg.id}.');
          await _localRepository.deleteRegulationData(serverReg.id);
          await _cloudRepository.downloadAndCacheRegulationData(serverReg.id);
          dev.log('[SYNC]   -> Sync complete for document ID ${serverReg.id}.');
        }
      }

      // 4. After sync, get the final list of regulations from server again to get correct `isDownloaded` status
      final finalRegulations = await _cloudRepository.getAvailableRegulations();
      dev.log('Fetched final list of regulations after sync.');

      controller.add(finalRegulations);
      controller.close();
    } catch (e) {
      dev.log('Error in GetAvailableRegulationsUseCase: $e');
      controller.addError(e);
    }
    return controller.stream;
  }
}

class SaveRegulationsUseCase extends CompletableUseCase<List<Regulation>> {
  final RegulationRepository _repository;
  SaveRegulationsUseCase(this._repository);

  @override
  Future<Stream<void>> buildUseCaseStream(List<Regulation>? params) async {
    final controller = StreamController<void>();
    try {
      if (params == null) {
        throw ArgumentError("regulations cannot be null");
      }
      await _repository.saveRegulations(params);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
