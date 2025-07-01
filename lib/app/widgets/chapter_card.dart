import 'package:flutter/material.dart';
import '../pages/chapter/model/chapter_arguments.dart';

class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.name,
    required this.num,
    required this.chapterOrderNum,
    required this.totalChapters,
    required this.chapterID,
  });

  final String name, num;
  final int chapterID, chapterOrderNum, totalChapters;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Navigator.pushNamed(
          context,
          '/chapter',
          arguments: ChapterArguments(
            chapterOrderNum: chapterOrderNum,
            totalChapters: totalChapters,
            scrollTo: 0,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            width: 1.0,
            color: Theme.of(context).shadowColor,
          ),
        ),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: num.isEmpty ? '' : '$num. ',
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    TextSpan(
                      text: name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
