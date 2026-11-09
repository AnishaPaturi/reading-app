import 'package:flutter/material.dart';
import '../theme/auth_palette.dart';

class ClayTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const ClayTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  State<ClayTextField> createState() => _ClayTextFieldState();
}

class _ClayTextFieldState extends State<ClayTextField> {
  late bool _obscured;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword;
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.controller.text,
      builder: (fieldState) {
        final hasError = fieldState.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 56,
              decoration: BoxDecoration(
                color: AuthPalette.inputBackground,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: hasError
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : (_isFocused
                          ? AuthPalette.inputBorderFocused
                          : AuthPalette.inputBorder),
                  width: _isFocused ? 1.8 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left Icon Pill Badge
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AuthPalette.iconBadge,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AuthPalette.iconBadge.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          color: AuthPalette.iconColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: _obscured,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      onSubmitted: widget.onFieldSubmitted,
                      onChanged: (val) {
                        fieldState.didChange(val);
                      },
                      style: const TextStyle(
                        color: AuthPalette.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          color: AuthPalette.textMuted,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  // Optional Eye Toggle for Password
                  if (widget.isPassword)
                    IconButton(
                      splashRadius: 20,
                      onPressed: () {
                        setState(() => _obscured = !_obscured);
                      },
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AuthPalette.eyeIcon,
                        size: 22,
                      ),
                    )
                  else
                    const SizedBox(width: 14),
                ],
              ),
            ),

            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 4),
                child: Text(
                  fieldState.errorText ?? '',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
