import 'package:flutter/material.dart' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'library_controller.dart';
import '../../widgets/regulation_app_bar.dart';

class LibraryView extends View {
  const LibraryView({Key? key}) : super(key: key);

  @override
  LibraryViewState createState() => LibraryViewState();
}

class LibraryViewState extends ViewState<LibraryView, LibraryController> {
  LibraryViewState() : super(LibraryController());

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          Theme.of(context).appBarTheme.toolbarHeight ?? 74.0,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
          ),
          child: RegulationAppBar(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Библиотека',
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // To balance the back button
              ],
            ),
          ),
        ),
      ),
      body: ControlledWidgetBuilder<LibraryController>(
        builder: (context, controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки: ${controller.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.refreshRegulations,
                      child: const Text('Попробовать снова'),
                    )
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => controller.refreshRegulations(),
            child: ListView.builder(
              itemCount: controller.regulations.length,
              itemBuilder: (context, index) {
                final regulation = controller.regulations[index];
                final isSelected =
                    controller.selectedRegulation?.id == regulation.id;
                final isProcessing = isSelected &&
                    (controller.isCheckingCache || controller.isDownloading);

                return AbsorbPointer(
                  absorbing: isProcessing,
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    margin: EdgeInsets.zero,
                    shape: Border(
                      bottom: BorderSide(
                        width: 1.0,
                        color: Theme.of(context).shadowColor,
                      ),
                    ),
                    child: ListTile(
                      title: Text(regulation.title,
                          style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: Text(regulation.description,
                          style: Theme.of(context).textTheme.bodyMedium),
                      onTap: () => controller.selectRegulation(regulation),
                      trailing: isProcessing
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.arrow_forward_ios),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
