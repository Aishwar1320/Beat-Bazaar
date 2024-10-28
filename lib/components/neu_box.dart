import 'package:beat_bazaar/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NeuBox extends StatelessWidget {
  final Widget? child;
  const NeuBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    bool isDarkmode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDarkmode ? Colors.black54 : Colors.grey.shade500,
              blurRadius: 5,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: isDarkmode ? Colors.grey.shade900 : Colors.grey.shade500,
              blurRadius: 15,
              offset: const Offset(-4, -4),
            )
          ]),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}
