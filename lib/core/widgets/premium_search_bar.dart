import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';

class PremiumSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  const PremiumSearchBar({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.focusNode,
  }) : super(key: key);

  @override
  State<PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<PremiumSearchBar> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    widget.controller.addListener(_onTextChanged);

    // Set initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncAnimation();
      }
    });
  }

  void _syncAnimation() {
    final shouldShowX = _isFocused || widget.controller.text.isNotEmpty;
    if (shouldShowX) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    _syncAnimation();
  }

  void _onTextChanged() {
    setState(() {});
    _syncAnimation();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: NeumorphicContainer(
            isPressed: true, // Sunken search input field
            borderRadius: BorderRadius.circular(24),
            bevel: 8.0,
            border: Border.all(
              color: _isFocused
                  ? primaryColor
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
              width: _isFocused ? 1.5 : 0.8,
            ),
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final isActionState = _isFocused || widget.controller.text.isNotEmpty;
                    if (isActionState) {
                      final hadText = widget.controller.text.isNotEmpty;
                      widget.controller.clear();
                      if (widget.onClear != null) widget.onClear!();
                      if (widget.onChanged != null) widget.onChanged!('');
                      if (!hadText) {
                        _focusNode.unfocus();
                      }
                    } else {
                      _focusNode.requestFocus();
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    color: Colors.transparent, // Expand tap area
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: _animationController.value * (3.14159 / 2),
                          child: Opacity(
                            opacity: (1.0 - _animationController.value).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: (1.0 - _animationController.value).clamp(0.4, 1.0),
                              child: Icon(
                                CupertinoIcons.search,
                                size: 22,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: (_animationController.value - 1.0) * (3.14159 / 2),
                          child: Opacity(
                            opacity: _animationController.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: _animationController.value.clamp(0.4, 1.0),
                              child: Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 20,
                                color: _isFocused ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
