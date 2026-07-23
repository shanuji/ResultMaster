import 'package:flutter/material.dart';

class AutoSelectTextField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;

  const AutoSelectTextField({super.key, required this.initialValue, required this.onChanged, this.decoration = const InputDecoration()});

  @override
  State<AutoSelectTextField> createState() => _AutoSelectTextFieldState();
}

class _AutoSelectTextFieldState extends State<AutoSelectTextField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller, focusNode: _focusNode, decoration: widget.decoration,
      onChanged: widget.onChanged,
    );
  }
}

class MarkInputField extends StatefulWidget {
  final String initialValue;
  final FocusNode focusNode;
  final Function(String) onFocusLostOrSubmitted;
  final VoidCallback? onNext;
  const MarkInputField({super.key, required this.initialValue, required this.focusNode, required this.onFocusLostOrSubmitted, this.onNext});
  @override
  State<MarkInputField> createState() => _MarkInputFieldState();
}

class _MarkInputFieldState extends State<MarkInputField> {
  late TextEditingController _controller; 
  String _lastSavedValue = '';

  @override
  void initState() { 
    super.initState(); 
    _controller = TextEditingController(text: widget.initialValue); 
    _lastSavedValue = widget.initialValue; 
    widget.focusNode.addListener(_handleFocusChange); 
  }

  @override
  void didUpdateWidget(covariant MarkInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) { 
      _controller.text = widget.initialValue; _lastSavedValue = widget.initialValue; 
    }
  }

  void _handleFocusChange() { 
    if (widget.focusNode.hasFocus) {
      if (_controller.text.isNotEmpty) {
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    } else {
      if (_controller.text != _lastSavedValue) { 
        _lastSavedValue = _controller.text; 
        widget.onFocusLostOrSubmitted(_controller.text); 
      } 
    } 
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller, focusNode: widget.focusNode, keyboardType: const TextInputType.numberWithOptions(decimal: true), 
      textInputAction: widget.onNext != null ? TextInputAction.next : TextInputAction.done, textAlign: TextAlign.center, 
      decoration: const InputDecoration(hintText: "-", border: InputBorder.none),
      onFieldSubmitted: (val) {
        if (val != _lastSavedValue) { _lastSavedValue = val; widget.onFocusLostOrSubmitted(val); }
        if (widget.onNext != null) widget.onNext!(); 
      },
    );
  }
}
