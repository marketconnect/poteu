import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/regulation_repository.dart';
import '../entities/regulation.dart';

class GetRegulations extends UseCase<List<Regulation>, void> {
  final RegulationRepository _regulationRepository;

  GetRegulations(this._regulationRepository);

  @override
  Future<Stream<List<Regulation>>> buildUseCaseStream(void params) async {
    final StreamController<List<Regulation>> controller = StreamController();
    try {
      final regulations = await _regulationRepository.getRegulations();
      controller.add(regulations);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
