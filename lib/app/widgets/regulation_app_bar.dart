import 'package:flutter/material.dart';

class RegulationAppBar extends StatelessWidget {
  const RegulationAppBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Theme.of(context).appBarTheme.toolbarHeight ?? 56.0,
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Theme.of(context).appBarTheme.shadowColor ??
                Colors.grey.shade300,
          ),
        ),
      ),
      child: child,
    );
  }
}
