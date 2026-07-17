import 'package:flutter/material.dart';

// ==========================================
// CUSTOM INPUT FIELD (Focus-Aware Fix)
// ==========================================
class MarkInputField extends StatefulWidget {
  final String initialValue;
  final Function(String) onFocusLostOrSubmitted;

  const MarkInputField({super.key, required this.initialValue, required this.onFocusLostOrSubmitted});

  @override
  State<MarkInputField> createState() => _MarkInputFieldState();
}

class _MarkInputFieldState extends State<MarkInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onFocusLostOrSubmitted(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MarkInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next, 
      textAlign: TextAlign.center,
      decoration: const InputDecoration(hintText: "-", border: InputBorder.none),
      onFieldSubmitted: (val) {
        widget.onFocusLostOrSubmitted(val);
      },
    );
  }
}
