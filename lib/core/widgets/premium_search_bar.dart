import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
  late Animation<double> _glowAnimation;
  late Animation<double> _iconRotationAnimation;
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

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    widget.controller.addListener(_onTextChanged);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTextChanged() {
    setState(() {});
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
              BoxShadow(
                color: primaryColor.withValues(alpha: (isDark ? 0.2 : 0.1) * _glowAnimation.value),
                blurRadius: _glowAnimation.value * 8,
                spreadRadius: _glowAnimation.value * 2,
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _isFocused
                  ? (isDark ? Colors.grey[900] : Colors.white)
                  : (isDark ? Colors.grey[850] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isFocused
                    ? primaryColor
                    : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                width: _isFocused ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                RotationTransition(
                  turns: _iconRotationAnimation,
                  child: Icon(
                    CupertinoIcons.search,
                    color: _isFocused ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 12),
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: (_isFocused || widget.controller.text.isNotEmpty)
                      ? GestureDetector(
                          key: const ValueKey('clear_btn'),
                          onTap: () {
                            final hadText = widget.controller.text.isNotEmpty;
                            widget.controller.clear();
                            if (widget.onClear != null) widget.onClear!();
                            if (widget.onChanged != null) widget.onChanged!('');
                            if (!hadText) {
                              _focusNode.unfocus();
                            }
                          },
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
