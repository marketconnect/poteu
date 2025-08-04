import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/regulation.dart';
import '../repositories/cloud_regulation_repository.dart';

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
