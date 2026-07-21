import 'package:flutter/material.dart';

class AutoSelectTextField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final bool enabled;

  const AutoSelectTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.style,
    this.enabled = true,
  });

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
  void didUpdateWidget(covariant AutoSelectTextField oldWidget) {
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
    return TextField(
      controller: _controller,
      focusNode: _focusNode, // <-- FIX: Changed from widget.focusNode to _focusNode
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      style: widget.style,
      enabled: widget.enabled,
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
      _controller.text = widget.initialValue; 
      _lastSavedValue = widget.initialValue; 
    }
    if (oldWidget.focusNode != widget.focusNode) { 
      oldWidget.focusNode.removeListener(_handleFocusChange); 
      widget.focusNode.addListener(_handleFocusChange); 
    }
  }

  @override
  void dispose() { 
    widget.focusNode.removeListener(_handleFocusChange); 
    _controller.dispose(); 
    super.dispose(); 
  }

  void _handleFocusChange() { 
    if (!widget.focusNode.hasFocus) { 
      if (_controller.text != _lastSavedValue) { 
        _lastSavedValue = _controller.text; 
        widget.onFocusLostOrSubmitted(_controller.text); 
      } 
    } 
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller, 
      focusNode: widget.focusNode, 
      keyboardType: const TextInputType.numberWithOptions(decimal: true), 
      textInputAction: TextInputAction.next, 
      textAlign: TextAlign.center, 
      decoration: const InputDecoration(hintText: "-", border: InputBorder.none),
      onFieldSubmitted: (val) {
        if (val != _lastSavedValue) { 
          _lastSavedValue = val; 
          widget.onFocusLostOrSubmitted(val); 
        }
        if (widget.onNext != null) { 
          WidgetsBinding.instance.addPostFrameCallback((_) { widget.onNext!(); }); 
        }
      },
    );
  }
}
