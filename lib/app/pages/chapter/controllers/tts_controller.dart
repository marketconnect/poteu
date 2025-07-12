import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'dart:async';
import '../../../../domain/entities/paragraph.dart';
import '../../../../domain/entities/tts_state.dart';
import '../../../../domain/usecases/tts_usecase.dart';
import '../../../../domain/repositories/tts_repository.dart';

class TtsController extends Controller {
  final TTSUseCase _ttsUseCase;
  StreamSubscription<TtsState>? _ttsStateSubscription;

  TtsState _ttsState = TtsState.stopped;
  bool _stopRequested = false;
  bool _isPlayingChapter = false;
  Paragraph? _currentTTSParagraph;
  String? _error;

  // Getters
  bool get isTTSPlaying => _ttsState == TtsState.playing;
  bool get isTTSPaused => _ttsState == TtsState.paused;
  bool get isTTSActive =>
      _ttsState == TtsState.playing || _ttsState == TtsState.paused;
  TtsState get ttsState => _ttsState;
  Paragraph? get currentTTSParagraph => _currentTTSParagraph;
  bool get isPlayingChapter => _isPlayingChapter;
  String? get error => _error;

  TtsController({required TTSRepository ttsRepository})
      : _ttsUseCase = TTSUseCase(ttsRepository) {
    // Initialize TTS state subscription
    _ttsStateSubscription = _ttsUseCase.stateStream.listen(
      (TtsState state) {
        _ttsState = state;
        print('🎵 TTS state changed to: $state');

        // Обрабатываем переходы состояний
        switch (state) {
          case TtsState.stopped:
            // Очищаем параграф только если это была запрошенная остановка
            if (_stopRequested) {
              print('🎵 TTS stopped as requested - clearing current paragraph');
              _currentTTSParagraph = null;
            } else {
              print(
                  '🎵 TTS stopped naturally - keeping current paragraph highlighted for 3 seconds');
              // Автоматически очищаем выделение через 3 секунды после естественного завершения
              Future.delayed(Duration(seconds: 3), () {
                if (_currentTTSParagraph != null &&
                    !_isPlayingChapter &&
                    _ttsState == TtsState.stopped) {
                  print(
                      '🎵 Auto-clearing paragraph highlight after natural completion');
                  _currentTTSParagraph = null;
                  refreshUI();
                }
              });
            }

            // Сбрасываем флаг остановки когда воспроизведение главы завершено
            if (!_isPlayingChapter) {
              _stopRequested = false;
              print(
                  '🎵 TTS state changed to $state - resetting stop flag (chapter playback finished)');
            }
            break;
          case TtsState.error:
            // При ошибке всегда очищаем
            print('🎵 TTS error - clearing current paragraph');
            _currentTTSParagraph = null;
            break;
          case TtsState.paused:
            // Если запрошена остановка во время паузы, принудительно останавливаем
            if (_stopRequested) {
              print('🎵 Stop requested while paused, forcing stop...');
              stopTTS();
            }
            break;
          default:
            break;
        }

        refreshUI();
      },
      onError: (error) {
        _error = 'TTS Error: ${error.toString()}';
        _ttsState = TtsState.error;
        _stopRequested = false;
        _isPlayingChapter = false;
        _currentTTSParagraph = null;
        print('🎵 TTS error in stream - clearing current paragraph');
        refreshUI();
      },
    );
  }

  @override
  void initListeners() {
    // TTS state subscription уже инициализирована в конструкторе
  }

  // TTS Control Methods
  Future<void> playText(String text) async {
    try {
      print(
          '🎵 PLAY TTS CALLED with text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      _error = null;
      _ttsUseCase.execute(
          _TTSUseCaseObserver(this), TTSUseCaseParams.speak(text));
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> playParagraph(Paragraph paragraph) async {
    try {
      print('🎵 PLAY PARAGRAPH TTS CALLED for paragraph: ${paragraph.id}');
      _currentTTSParagraph = paragraph;
      _error = null;
      refreshUI();

      // Extract plain text from paragraph content
      final plainText = _extractPlainText(paragraph.content);
      _ttsUseCase.execute(
          _TTSUseCaseObserver(this), TTSUseCaseParams.speak(plainText));
    } catch (e) {
      _error = e.toString();
      _currentTTSParagraph = null;
      refreshUI();
    }
  }

  Future<void> playChapter(List<Paragraph> paragraphs,
      {int startIndex = 0}) async {
    try {
      print(
          '🎵 PLAY CHAPTER TTS CALLED with ${paragraphs.length} paragraphs starting from index $startIndex');
      _isPlayingChapter = true;
      _stopRequested = false;
      _error = null;

      await _playParagraphsSequentially(paragraphs, startIndex);
    } catch (e) {
      _error = e.toString();
      _isPlayingChapter = false;
      _currentTTSParagraph = null;
      refreshUI();
    }
  }

  Future<void> _playParagraphsSequentially(
      List<Paragraph> paragraphs, int startIndex) async {
    for (int i = startIndex; i < paragraphs.length; i++) {
      if (_stopRequested || !_isPlayingChapter) {
        print('🎵 Chapter playback stopped at paragraph $i');
        break;
      }

      final paragraph = paragraphs[i];
      print(
          '🎵 Playing paragraph ${i + 1}/${paragraphs.length}: ${paragraph.id}');

      // Set current paragraph for UI highlighting
      _currentTTSParagraph = paragraph;
      refreshUI();

      // Extract plain text and play
      final plainText = _extractPlainText(paragraph.content);
      if (plainText.isNotEmpty) {
        await _playTextAndWait(plainText);
      }

      // Small delay between paragraphs
      if (i < paragraphs.length - 1 && !_stopRequested) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    // Chapter playback completed
    _isPlayingChapter = false;
    print('🎵 Chapter playback completed');
    refreshUI();
  }

  Future<void> _playTextAndWait(String text) async {
    final completer = Completer<void>();

    // Create a temporary observer for this specific text
    final observer = _TemporaryTTSUseCaseObserver(completer);

    try {
      _ttsUseCase.execute(observer, TTSUseCaseParams.speak(text));
      await completer.future;
    } catch (e) {
      print('🎵 Error playing text: $e');
      completer.complete();
    }
  }

  Future<void> stopTTS() async {
    try {
      print(
          '🎵 STOP TTS CALLED - Setting stop flag and stopping chapter playback');
      _stopRequested = true;
      _isPlayingChapter = false;
      _currentTTSParagraph = null;
      print('🎵 TTS: Clearing current paragraph in stopTTS');
      refreshUI();

      // Вызываем stop() в TTS репозитории
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.stop());

      // Дополнительная проверка: если TTS все еще в состоянии paused, принудительно останавливаем
      if (_ttsState == TtsState.paused) {
        print('🎵 TTS still paused after stop call, forcing stop again...');
        await Future.delayed(Duration(milliseconds: 200));
        _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.stop());
      }
    } catch (e) {
      print('🎵 Error in stopTTS(): $e');
      _error = e.toString();
      _currentTTSParagraph = null;
      print('🎵 TTS: Clearing current paragraph due to error in stopTTS');
      refreshUI();
    }
  }

  Future<void> pauseTTS() async {
    try {
      print('🎵 PAUSE TTS CALLED');
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.pause());
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  Future<void> resumeTTS() async {
    try {
      print('🎵 RESUME TTS CALLED');
      _ttsUseCase.execute(_TTSUseCaseObserver(this), TTSUseCaseParams.resume());
    } catch (e) {
      _error = e.toString();
      refreshUI();
    }
  }

  // Utility methods
  String _extractPlainText(String htmlContent) {
    // Remove HTML tags and decode entities
    String plainText = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ') // Replace non-breaking spaces
        .replaceAll('&amp;', '&') // Replace ampersands
        .replaceAll('&lt;', '<') // Replace less than
        .replaceAll('&gt;', '>') // Replace greater than
        .replaceAll('&quot;', '"') // Replace quotes
        .replaceAll('&#39;', "'") // Replace apostrophes
        .trim();

    // Remove extra whitespace
    plainText = plainText.replaceAll(RegExp(r'\s+'), ' ');

    return plainText;
  }

  List<String> _splitTextIntoChunks(String text, {int maxChunkSize = 500}) {
    if (text.length <= maxChunkSize) {
      return [text];
    }

    final List<String> chunks = [];
    int startIndex = 0;

    while (startIndex < text.length) {
      int endIndex = startIndex + maxChunkSize;

      // If we're not at the end, try to find a good break point
      if (endIndex < text.length) {
        // Look for sentence endings (., !, ?) or paragraph breaks
        int lastGoodBreak = startIndex;
        for (int i = startIndex; i < endIndex; i++) {
          if (text[i] == '.' ||
              text[i] == '!' ||
              text[i] == '?' ||
              text[i] == '\n') {
            lastGoodBreak = i + 1;
          }
        }

        // If we found a good break point, use it
        if (lastGoodBreak > startIndex) {
          endIndex = lastGoodBreak;
        }
      } else {
        endIndex = text.length;
      }

      final chunk = text.substring(startIndex, endIndex).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      startIndex = endIndex;
    }

    return chunks;
  }

  void setCurrentTTSParagraph(Paragraph? paragraph) {
    _currentTTSParagraph = paragraph;
    refreshUI();
  }

  void clearError() {
    _error = null;
    refreshUI();
  }

  @override
  void onDisposed() {
    // Cancel TTS state subscription and reset stop flag
    _ttsStateSubscription?.cancel();
    _stopRequested = false;
    _isPlayingChapter = false;
    super.onDisposed();
  }
}

class _TTSUseCaseObserver extends Observer<void> {
  final TtsController _controller;

  _TTSUseCaseObserver(this._controller);

  @override
  void onComplete() {
    print(
        '🎵 TTS Observer: onComplete called - NOT clearing current paragraph');
    // НЕ очищаем текущий читаемый параграф при завершении TTS
    // Пусть пользователь сам остановит или это сделает stopTTS()
    _controller.refreshUI();
  }

  @override
  void onError(e) {
    print('❌ TTS Observer: onError called with: $e');
    _controller._error = e.toString();
    // Очищаем текущий читаемый параграф только при ошибке TTS
    _controller._currentTTSParagraph = null;
    print('🎵 TTS Observer: Clearing current paragraph in onError');
    _controller.refreshUI();
  }

  @override
  void onNext(_) {
    print('🎵 TTS Observer: onNext called');
  }
}

class _TemporaryTTSUseCaseObserver extends Observer<void> {
  final Completer<void> _completer;

  _TemporaryTTSUseCaseObserver(this._completer);

  @override
  void onComplete() {
    _completer.complete();
  }

  @override
  void onError(e) {
    _completer.completeError(e);
  }

  @override
  void onNext(_) {
    // Do nothing for temporary observer
  }
}
