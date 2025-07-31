import 'package:flutter/material.dart';

class SafeButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration debounceDuration;
  final ButtonStyle? style;

  const SafeButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.debounceDuration = const Duration(seconds: 2),
    this.style,
  });

  @override
  State<SafeButton> createState() => _SafeButtonState();
}

class _SafeButtonState extends State<SafeButton> {
  bool _isClicked = false;

  void _handleTap() {
    if (_isClicked) return;

    setState(() {
      _isClicked = true;
    });

    widget.onPressed();

    Future.delayed(widget.debounceDuration, () {
      if (mounted) {
        setState(() {
          _isClicked = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isClicked ? null : _handleTap,
      style: widget.style,
      child: widget.child,
    );
  }
}
