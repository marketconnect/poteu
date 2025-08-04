import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/cloud_regulation_repository.dart';

class DownloadRegulationDataUseCase extends CompletableUseCase<int> {
  final CloudRegulationRepository _repository;
  DownloadRegulationDataUseCase(this._repository);

  @override
  Future<Stream<void>> buildUseCaseStream(int? params) async {
    final controller = StreamController<void>();
    try {
      if (params == null) {
        throw ArgumentError("ruleId cannot be null");
      }
      await _repository.downloadAndCacheRegulationData(params);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
