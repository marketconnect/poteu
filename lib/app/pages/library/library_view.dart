import 'package:flutter/material.dart' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'library_controller.dart';
import '../../widgets/regulation_app_bar.dart';

class LibraryView extends View {
  final SubscriptionRepository subscriptionRepository;

  const LibraryView({Key? key, required this.subscriptionRepository})
      : super(key: key);

  @override
  LibraryViewState createState() => LibraryViewState(subscriptionRepository);
}

class LibraryViewState extends ViewState<LibraryView, LibraryController> {
  LibraryViewState(SubscriptionRepository subscriptionRepository)
      : super(LibraryController(subscriptionRepository));

  Widget _buildDefaultAppBar(
      BuildContext context, LibraryController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        IconButton(
          onPressed: controller.toggleSearch,
          icon: Icon(
            Icons.search,
            size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAppBar(BuildContext context, LibraryController controller) {
    return Row(
      children: [
        IconButton(
          onPressed: controller.toggleSearch,
          icon: Icon(
            Icons.arrow_back,
            size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller.searchController,
            autofocus: true,
            style: Theme.of(context).appBarTheme.toolbarTextStyle,
            cursorColor: Theme.of(context).appBarTheme.foregroundColor,
            decoration: InputDecoration(
              hintText: 'Поиск...',
              hintStyle: Theme.of(context).appBarTheme.toolbarTextStyle,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, LibraryController controller) {
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

    if (controller.regulations.isEmpty &&
        controller.searchController.text.isNotEmpty) {
      return Center(
        child: Text(
          'По вашему запросу ничего не найдено.',
          style: Theme.of(context).textTheme.bodyLarge,
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
          final isProcessing =
              isSelected && (controller.isCheckingCache || controller.isDownloading);
          final isPremium = regulation.isPremium;
          final canAccess = !isPremium || controller.isSubscribed;

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
                leading: (isPremium || regulation.isDownloaded)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPremium && !canAccess)
                            const Icon(
                              Icons.lock_outline,
                              color: Colors.orange,
                            ),
                          if (regulation.isDownloaded) ...[
                            const Icon(
                              Icons.cloud_done_outlined,
                              color: Colors.blue,
                            ),
                          ]
                        ],
                      )
                    : null,
                title: Text(regulation.title,
                    style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(regulation.description,
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  if (canAccess) {
                    controller.selectRegulation(regulation);
                  } else {
                    Navigator.of(context).pushNamed('/subscription');
                  }
                },
                trailing: isProcessing
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.arrow_forward_ios),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget get view {
    return ControlledWidgetBuilder<LibraryController>(
        builder: (context, controller) {
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
              child: controller.isSearching
                  ? _buildSearchAppBar(context, controller)
                  : _buildDefaultAppBar(context, controller),
            ),
          ),
        ),
        body: _buildBody(context, controller),
      );
    });
  }
}
