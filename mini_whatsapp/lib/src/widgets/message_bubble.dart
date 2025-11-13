import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool mine;
  final String? audioUrl;
  final VoidCallback? onPlay;

  const MessageBubble({
    super.key,
    required this.text,
    required this.mine,
    this.audioUrl,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final bg = mine ? Colors.green[200] : Colors.grey[300];
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: audioUrl != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text('Voice message'),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: onPlay, child: const Text('Play')),
                  ],
                )
              : Text(text),
        ),
      ],
    );
  }
}
