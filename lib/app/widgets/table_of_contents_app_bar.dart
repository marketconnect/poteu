import 'package:flutter/material.dart';

class TableOfContentsAppBar extends StatelessWidget {
  const TableOfContentsAppBar({
    super.key,
    required this.title,
    required this.name,
  });

  final String title, name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            return MediaQuery.of(context).orientation == Orientation.portrait
                ? IconButton(
                    onPressed: () async {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: Icon(
                      Icons.menu,
                      size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                      color: Theme.of(context).appBarTheme.iconTheme?.color ??
                          Colors.black,
                    ),
                  )
                : Container();
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(name)),
              );
            },
            child: Text(
              title,
              style: Theme.of(context).appBarTheme.titleTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          onPressed: () async {
            Navigator.pushNamed(
              context,
              '/search',
            );
          },
          icon: Icon(
            Icons.search,
            size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
            color:
                Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
