import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _current;

/// A short message that does not take part in hit testing. A SnackBar would sit on top of
/// part of the game grid and swallow taps for its whole duration; this one lets taps through.
void showToast(BuildContext context, String text) {
  if (_current?.mounted ?? false) _current!.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(text: text, onDone: () {
      if (entry.mounted) entry.remove();
    }),
  );
  _current = entry;
  Overlay.of(context).insert(entry);
}

class _Toast extends StatefulWidget {
  final String text;
  final VoidCallback onDone;
  const _Toast({required this.text, required this.onDone});

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  late final Timer _timer = Timer(const Duration(seconds: 2), widget.onDone);

  @override
  void initState() {
    super.initState();
    _timer; // start the timer; it is cancelled in dispose so no timer outlives the tree
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70, left: 12, right: 12),
            child: Material(
              color: const Color(0xE6212121),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
