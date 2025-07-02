import 'package:flutter/material.dart' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../domain/entities/note.dart';
import '../../widgets/regulation_app_bar.dart';
import 'notes_controller.dart';
import '../chapter/model/chapter_arguments.dart';

class NotesView extends View {
  const NotesView({Key? key}) : super(key: key);

  @override
  NotesViewState createState() => NotesViewState(NotesController());
}

class NotesViewState extends ViewState<NotesView, NotesController> {
  NotesViewState(NotesController controller) : super(controller);

  @override
  void initState() {
    super.initState();
    // Refresh notes when the view is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Access controller through the view state
      if (mounted) {
        // Use a simple trigger to refresh - in next build cycle controller will refresh
      }
    });
  }

  @override
  Widget get view {
    return ControlledWidgetBuilder<NotesController>(
      builder: (context, controller) {
        // Refresh notes once when first building
        if (!controller.hasNotes && !controller.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.refreshNotes();
          });
        }

        return Scaffold(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        size:
                            Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                        color: Theme.of(context).appBarTheme.iconTheme?.color,
                      ),
                    ),
                    Text(
                      'Заметки',
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                    IconButton(
                      onPressed: () {
                        _showSortBottomSheet(controller);
                      },
                      icon: Icon(
                        Icons.sort,
                        size:
                            Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                        color: Theme.of(context).appBarTheme.iconTheme?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              controller.refreshNotes();
            },
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.notes.isEmpty
                    ? const Center(
                        child: Text(
                          'У вас пока нет заметок',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.notes.length,
                        itemBuilder: (context, index) {
                          final note = controller.notes[index];
                          return _buildNoteItem(note, controller);
                        },
                      ),
          ),
        );
      },
    );
  }

  Widget _buildNoteItem(Note note, NotesController controller) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => _navigateToChapter(note),
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            width * 0.04,
            width * 0.06,
            width * 0.075,
            width * 0.05,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First row: bookmark icon + chapter name
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          color: note.link.color,
                          size: width * 0.05,
                        ),
                        SizedBox(width: width * 0.04),
                        Expanded(
                          child: Text(
                            '${note.regulationTitle}. ${note.chapterName}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: width * 0.045,
                              color:
                                  Theme.of(context).textTheme.bodyLarge!.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: width * 0.04),
                    // Second row: indented text content
                    Row(
                      children: [
                        SizedBox(
                            width: width * 0.1), // Indent to align with text
                        Expanded(
                          child: Text(
                            note.link.text,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: width * 0.03,
                              color: Theme.of(context)
                                  .appBarTheme
                                  .toolbarTextStyle!
                                  .color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              GestureDetector(
                onTap: () => _showDeleteConfirmation(note, controller),
                child: Icon(
                  Icons.close,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet(NotesController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Wrap(
        alignment: WrapAlignment.center,
        children: [
          // Sort by date option
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await controller.setSortByDate();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              height: 70,
              width: MediaQuery.of(context).size.width * 0.95,
              child: Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  Icon(
                    Icons.date_range,
                    color:
                        Theme.of(context).appBarTheme.toolbarTextStyle!.color,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  const Text('Сортировать по дате'),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            height: 1,
            width: MediaQuery.of(context).size.width * 0.95,
            color: Theme.of(context).dividerColor,
          ),
          // Sort by color option
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await controller.setSortByColor();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
              ),
              height: 70,
              width: MediaQuery.of(context).size.width * 0.95,
              child: Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  Icon(
                    Icons.color_lens_outlined,
                    color:
                        Theme.of(context).appBarTheme.toolbarTextStyle!.color,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  const Text('Сортировать по цвету'),
                ],
              ),
            ),
          ),
          // Cancel option
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              height: 70,
              width: MediaQuery.of(context).size.width * 0.95,
              child: const Center(child: Text("Отменить")),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Note note, NotesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text(
          'Вы уверены, что хотите удалить заметку "${note.link.text}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.deleteNote(note);
              if (controller.error != null) {
                _showErrorSnackBar(controller.error!);
              } else {
                _showSnackBar('Заметка удалена');
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _navigateToChapter(Note note) {
    print('=== NAVIGATING TO CHAPTER ===');
    print('Note chapterOrderNum: ${note.chapterOrderNum}');
    print('Note originalParagraphId: ${note.originalParagraphId}');

    // Navigate to chapter with specific paragraph using ChapterArguments
    Navigator.pushNamed(
      context,
      '/chapter',
      arguments: ChapterArguments(
        totalChapters: 6, // Would need to be dynamic in a real app
        chapterOrderNum:
            note.chapterOrderNum, // Use the correct chapter order number
        scrollTo:
            note.originalParagraphId, // Use originalParagraphId for scrolling
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
