import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/cloud_regulation_repository.dart';

class IsRegulationCachedUseCase extends UseCase<bool, int> {
  final CloudRegulationRepository _repository;
  IsRegulationCachedUseCase(this._repository);

  @override
  Future<Stream<bool>> buildUseCaseStream(int? params) async {
    final controller = StreamController<bool>();
    try {
      if (params == null) {
        throw ArgumentError("ruleId cannot be null");
      }
      final isCached = await _repository.isRegulationDataCached(params);
      controller.add(isCached);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
