import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/regulation.dart';
import '../repositories/cloud_regulation_repository.dart';
import '../repositories/regulation_repository.dart';

class GetAvailableRegulationsUseCase extends UseCase<List<Regulation>, void> {
  final CloudRegulationRepository _repository;

  GetAvailableRegulationsUseCase(this._repository);

  @override
  Future<Stream<List<Regulation>>> buildUseCaseStream(void params) async {
    final controller = StreamController<List<Regulation>>();
    try {
      final regulations = await _repository.getAvailableRegulations();
      controller.add(regulations);
      controller.close();
    } catch (e) {
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
