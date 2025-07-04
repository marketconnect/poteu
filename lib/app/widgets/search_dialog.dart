import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/search_result.dart';

class SearchDialog extends StatefulWidget {
  final String initialQuery;
  final bool isSearching;
  final List<SearchResult> searchResults;
  final Function(String) onSearch;
  final Function(SearchResult) onResultSelected;
  final Function() onClose;

  const SearchDialog({
    Key? key,
    required this.initialQuery,
    required this.isSearching,
    required this.searchResults,
    required this.onSearch,
    required this.onResultSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  widget.onSearch('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            if (widget.isSearching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else if (widget.searchResults.isEmpty &&
                _searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Ничего не найдено'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.searchResults.length,
                  itemBuilder: (context, index) {
                    final result = widget.searchResults[index];
                    return ListTile(
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: result.text.substring(0, result.matchStart),
                              style: DefaultTextStyle.of(context).style,
                            ),
                            TextSpan(
                              text: result.text.substring(
                                result.matchStart,
                                result.matchEnd,
                              ),
                              style:
                                  DefaultTextStyle.of(context).style.copyWith(
                                        backgroundColor: Colors.yellow,
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                            TextSpan(
                              text: result.text.substring(result.matchEnd),
                              style: DefaultTextStyle.of(context).style,
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        widget.onResultSelected(result);
                        widget.onClose();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
