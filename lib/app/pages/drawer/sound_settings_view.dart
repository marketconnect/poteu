import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../domain/repositories/tts_repository.dart';
import 'sound_settings_controller.dart';

class SoundSettingsView extends fca.View {
  final dynamic settingsRepository;
  final TTSRepository ttsRepository;

  const SoundSettingsView({
    super.key,
    required this.settingsRepository,
    required this.ttsRepository,
  });

  @override
  State<StatefulWidget> createState() =>
      _SoundSettingsViewState(settingsRepository, ttsRepository);
}

class _SoundSettingsViewState
    extends fca.ViewState<SoundSettingsView, SoundSettingsController> {
  final dynamic settingsRepository;
  final TTSRepository ttsRepository;

  _SoundSettingsViewState(this.settingsRepository, this.ttsRepository)
      : super(SoundSettingsController(settingsRepository, ttsRepository));

  @override
  Widget get view {
    return fca.ControlledWidgetBuilder<SoundSettingsController>(
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    controller.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _buildVolumeSlider(controller),
              _buildPitchSlider(controller),
              _buildRateSlider(controller),
              _buildVoiceSelector(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVolumeSlider(SoundSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Громкость'),
        ),
        Slider(
          value: controller.volume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: (controller.volume * 100).round().toString(),
          onChanged: (value) => controller.setVolume(value),
        ),
      ],
    );
  }

  Widget _buildPitchSlider(SoundSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Высота голоса'),
        ),
        Slider(
          value: controller.pitch,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: controller.pitch.toStringAsFixed(2),
          onChanged: (value) => controller.setPitch(value),
        ),
      ],
    );
  }

  Widget _buildRateSlider(SoundSettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Скорость речи'),
        ),
        Slider(
          value: controller.rate,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: controller.rate.toStringAsFixed(2),
          onChanged: (value) => controller.setRate(value),
        ),
      ],
    );
  }

  Widget _buildVoiceSelector(SoundSettingsController controller) {
    if (controller.availableVoices.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Голос'),
        ),
        DropdownButton<String>(
          value: controller.selectedVoice.isNotEmpty
              ? controller.selectedVoice
              : null,
          hint: const Text('Выберите голос'),
          isExpanded: true,
          items: controller.availableVoices.map((voice) {
            return DropdownMenuItem<String>(
              value: voice['name'] as String,
              child: Text(voice['name'] as String),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              controller.setVoice(value);
            }
          },
        ),
      ],
    );
  }
}
