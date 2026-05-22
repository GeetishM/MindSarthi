import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';

class AnimatedActionMenu extends StatefulWidget {
  final List<Widget> children;
  final double iconSize;
  final bool expandLeft;

  const AnimatedActionMenu({
    super.key,
    required this.children,
    this.iconSize = 22.0,
    this.expandLeft = true,
  });

  @override
  State<AnimatedActionMenu> createState() => _AnimatedActionMenuState();
}

class _AnimatedActionMenuState extends State<AnimatedActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final triggerButton = GestureDetector(
      onTap: _toggleMenu,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: RotationTransition(
          turns: _rotateAnimation,
          child: Icon(
            _isOpen ? CupertinoIcons.xmark : CupertinoIcons.ellipsis,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            size: widget.iconSize,
          ),
        ),
      ),
    );

    final actionsRow = SizeTransition(
      sizeFactor: _expandAnimation,
      axis: Axis.horizontal,
      axisAlignment: widget.expandLeft ? 1.0 : -1.0,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.children.map((child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: child,
            );
          }).toList(),
        ),
      ),
    );

    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      borderRadius: BorderRadius.circular(20),
      color: isDark ? AppColors.darkSurface2 : AppColors.surface,
      bevel: 6.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.expandLeft 
            ? [actionsRow, triggerButton]
            : [triggerButton, actionsRow],
      ),
    );
  }
}
