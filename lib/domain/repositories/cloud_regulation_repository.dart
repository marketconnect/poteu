import '../entities/regulation.dart';

abstract class CloudRegulationRepository {
  Future<List<Regulation>> getAvailableRegulations();
  Future<bool> isRegulationDataCached(int ruleId);
  Future<void> downloadAndCacheRegulationData(int ruleId);
}
