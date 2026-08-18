/// A rule and a label — how every section starts in the web app.
library;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, color: palette.text),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(title.toUpperCase(), style: label(color: palette.text))),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}
