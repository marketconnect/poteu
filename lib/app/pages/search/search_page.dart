import 'package:flutter/material.dart';
import '../../../domain/repositories/regulation_repository.dart';

class SearchPage extends StatelessWidget {
  final RegulationRepository regulationRepository;

  const SearchPage({
    required this.regulationRepository,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                // TODO: Implement search
              },
              decoration: const InputDecoration(
                hintText: 'Введите текст для поиска...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Введите текст для поиска'),
            ),
          ),
        ],
      ),
    );
  }
}
