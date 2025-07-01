# POTEU

A Flutter application for viewing and managing regulations, built using clean architecture principles.

## Features

- View regulations and chapters
- Search through regulations
- Save and manage notes
- Customize app settings (theme, font size, language)
- Text-to-speech support

## Architecture

The application follows clean architecture principles with the following layers:

### Domain Layer
- Entities: Core business objects
- Repositories: Abstract interfaces
- Use Cases: Business logic

### Data Layer
- Repository Implementations
- Database Helper
- Data Models

### Presentation Layer
- Pages (Views, Controllers, Presenters)
- Widgets
- Theme

## Getting Started

1. Install Flutter (version 3.0.0 or higher)
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Dependencies

- flutter_clean_architecture: Clean architecture implementation
- shared_preferences: Settings storage
- sqflite: SQLite database
- flutter_tts: Text-to-speech support

## Project Structure

```
lib/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── helpers/
│   └── repositories/
└── presentation/
    ├── pages/
    │   ├── app/
    │   ├── table_of_contents/
    │   ├── notes/
    │   ├── search/
    │   └── settings/
    ├── theme/
    └── widgets/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
