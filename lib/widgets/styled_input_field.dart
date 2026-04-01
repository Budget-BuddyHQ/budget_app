import 'package:flutter/material.dart';

class StyledInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final int minLines;
  final BorderSide focusedBorder;
  final BorderSide enabledBorder;
  final Color backgroundColor;
  final Color labelColor;
  final Color hintColor;

  const StyledInputField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines = 1,
    this.focusedBorder = const BorderSide(
      color: Color(0xFF76FF03),
      width: 2,
    ),
    this.enabledBorder = const BorderSide(
      color: Color(0xFF85EFAC),
      width: 1.5,
    ),
    this.backgroundColor = const Color(0xFF1B3329),
    this.labelColor = Colors.white,
    this.hintColor = const Color.fromRGBO(255, 255, 255, 0.5),
  }) : super(key: key);

  @override
  State<StyledInputField> createState() => _StyledInputFieldState();
}

class _StyledInputFieldState extends State<StyledInputField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: widget.labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? widget.focusedBorder.color
                  : widget.enabledBorder.color,
              width: _isFocused ? 2 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF76FF03).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            onChanged: widget.onChanged,
            validator: widget.validator,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.hintColor,
                fontSize: 14,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
