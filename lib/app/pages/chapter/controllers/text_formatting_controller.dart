import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../domain/entities/paragraph.dart';
import '../../../../data/repositories/data_regulation_repository.dart';
import 'dart:developer' as dev;

class TextFormattingController extends Controller {
  final DataRegulationRepository _dataRepository =
      DataRegulationRepository(); // No longer needs DatabaseHelper

  bool _isBottomBarExpanded = false;
  bool _isBottomBarWhiteMode = false;
  Paragraph? _selectedParagraph;
  int _selectionStart = 0;
  int _selectionEnd = 0;
  String _lastSelectedText = '';
  final List<int> _colorsList = [
    0xFFFFFF00, // Yellow
    0xFFFF8C00, // Orange
    0xFF00FF00, // Green
    0xFF0000FF, // Blue
    0xFFFF1493, // Pink
    0xFF800080, // Purple
    0xFFFF0000, // Red
    0xFF00FFFF, // Cyan
  ];
  int _activeColorIndex = 0;
  String? _error;

  // Bottom Bar getters
  bool get isBottomBarExpanded => _isBottomBarExpanded;
  bool get isBottomBarWhiteMode => _isBottomBarWhiteMode;

  // Selection getters
  Paragraph? get selectedParagraph => _selectedParagraph;
  int get selectionStart => _selectionStart;
  int get selectionEnd => _selectionEnd;
  String get lastSelectedText => _lastSelectedText;

  // Color getters
  List<int> get colorsList => _colorsList;
  int get activeColorIndex => _activeColorIndex;
  int get activeColor => _colorsList[_activeColorIndex];

  // Error getter
  String? get error => _error;

  TextFormattingController();

  @override
  void initListeners() {
    // Initialize listeners if needed
  }

  // Bottom Bar Management
  void toggleBottomBar() {
    _isBottomBarExpanded = !_isBottomBarExpanded;
    refreshUI();
  }

  void setBottomBarExpanded(bool expanded) {
    _isBottomBarExpanded = expanded;
    refreshUI();
  }

  void toggleBottomBarWhiteMode() {
    _isBottomBarWhiteMode = !_isBottomBarWhiteMode;
    refreshUI();
  }

  void setBottomBarWhiteMode(bool whiteMode) {
    _isBottomBarWhiteMode = whiteMode;
    refreshUI();
  }

  // Text Selection Management
  void setSelectedParagraph(Paragraph? paragraph) {
    _selectedParagraph = paragraph;
    refreshUI();
  }

  void setSelectionRange(int start, int end) {
    _selectionStart = start;
    _selectionEnd = end;
    refreshUI();
  }

  void setLastSelectedText(String text) {
    _lastSelectedText = text;
    refreshUI();
  }

  void clearSelection() {
    _selectedParagraph = null;
    _selectionStart = 0;
    _selectionEnd = 0;
    _lastSelectedText = '';
    refreshUI();
  }

  // Color Management
  void setActiveColorIndex(int index) {
    if (index >= 0 && index < _colorsList.length) {
      _activeColorIndex = index;
      refreshUI();
    }
  }

  void nextColor() {
    _activeColorIndex = (_activeColorIndex + 1) % _colorsList.length;
    refreshUI();
  }

  void previousColor() {
    _activeColorIndex =
        (_activeColorIndex - 1 + _colorsList.length) % _colorsList.length;
    refreshUI();
  }

  // Text Formatting Actions - Placeholder methods for future implementation
  Future<void> applyHighlight() async {
    if (_selectedParagraph == null || _lastSelectedText.isEmpty) {
      return;
    }

    try {
      // TODO: Implement formatting logic when repository methods are available
      dev.log(
          'Applying highlight to text: $_lastSelectedText with color: $activeColor');
      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка применения выделения: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> applyUnderline() async {
    if (_selectedParagraph == null || _lastSelectedText.isEmpty) {
      return;
    }

    try {
      // TODO: Implement formatting logic when repository methods are available
      dev.log('Applying underline to text: $_lastSelectedText');
      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка применения подчеркивания: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> applyBold() async {
    if (_selectedParagraph == null || _lastSelectedText.isEmpty) {
      return;
    }

    try {
      // TODO: Implement formatting logic when repository methods are available
      dev.log('Applying bold to text: $_lastSelectedText');
      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка применения жирного шрифта: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> applyItalic() async {
    if (_selectedParagraph == null || _lastSelectedText.isEmpty) {
      return;
    }

    try {
      // TODO: Implement formatting logic when repository methods are available
      dev.log('Applying italic to text: $_lastSelectedText');
      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка применения курсива: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> removeFormatting() async {
    if (_selectedParagraph == null || _lastSelectedText.isEmpty) {
      return;
    }

    try {
      // TODO: Implement formatting removal logic when repository methods are available
      dev.log('Removing formatting from text: $_lastSelectedText');
      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка удаления форматирования: ${e.toString()}';
      refreshUI();
    }
  }

  Future<void> saveEditedParagraph(
      Paragraph paragraph, String editedContent) async {
    try {
      // Save to database
      await _dataRepository.saveEditedParagraph(
        paragraph.originalId,
        editedContent,
        paragraph,
      );

      _error = null;
      refreshUI();
    } catch (e) {
      _error = 'Ошибка сохранения: ${e.toString()}';
      refreshUI();
    }
  }

  // Utility methods
  bool get hasSelection =>
      _selectedParagraph != null && _lastSelectedText.isNotEmpty;

  bool get canApplyFormatting => hasSelection && _selectedParagraph != null;

  void clearError() {
    _error = null;
    refreshUI();
  }

  @override
  void onDisposed() {
    // Clean up any resources if needed
    super.onDisposed();
  }
}
