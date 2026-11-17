import 'package:flutter/material.dart';

/// Small rounded labels such as "128GB", "Grade A", "ex-UK".
class SpecChips extends StatelessWidget {
  const SpecChips(this.specs, {super.key, this.dense = false});

  final List<String> specs;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in specs)
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: dense ? 7 : 10, vertical: dense ? 2 : 5),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              s,
              style: TextStyle(
                fontSize: dense ? 11 : 13,
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
