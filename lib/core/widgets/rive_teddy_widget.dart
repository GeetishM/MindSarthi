import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// A reusable widget that displays the Rive "Teddy Bear" login character
/// and exposes controls for the state machine inputs.
///
/// Usage:
/// ```dart
/// RiveTeddyWidget(
///   onControllerReady: (ctrl) => _teddyCtrl = ctrl,
/// )
/// ```
class RiveTeddyWidget extends StatefulWidget {
  /// Called when the Rive state machine is initialized and ready.
  final ValueChanged<RiveTeddyController>? onControllerReady;

  /// Height of the Rive animation container. Defaults to 250.
  final double height;

  const RiveTeddyWidget({
    super.key,
    this.onControllerReady,
    this.height = 250,
  });

  @override
  State<RiveTeddyWidget> createState() => _RiveTeddyWidgetState();
}

class _RiveTeddyWidgetState extends State<RiveTeddyWidget> {
  void _onRiveInit(Artboard artboard) {
    // Try to find any available state machine on the artboard
    StateMachineController? controller;

    // Try common state machine names
    for (final name in [
      'Login Machine',
      'State Machine 1',
      'State Machine',
      'Main State Machine',
    ]) {
      controller = StateMachineController.fromArtboard(artboard, name);
      if (controller != null) break;
    }

    if (controller != null) {
      artboard.addController(controller);
      final teddyCtrl = RiveTeddyController._(controller);
      widget.onControllerReady?.call(teddyCtrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: RiveAnimation.asset(
        'assets/rive/teddy_login.riv',
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}

/// Controller that wraps the Rive state machine inputs for the Teddy login.
///
/// Provides a clean API to control the bear's behavior:
/// - [isChecking] — bear looks down at the text field (maps to `isFocus`)
/// - [isHandsUp] — bear covers its eyes with its paws (maps to `isPrivateField`)
/// - [look] — controls eye tracking direction (0–100)
/// - [triggerSuccess] — fires the happy celebration animation
/// - [triggerFail] — fires the sad/shake animation
class RiveTeddyController {
  final StateMachineController _controller;

  late final SMIBool? _isFocus;
  late final SMIBool? _isPrivateField;
  late final SMINumber? _numLook;
  late final SMITrigger? _successTrigger;
  late final SMITrigger? _failTrigger;

  RiveTeddyController._(this._controller) {
    _isFocus = _controller.findInput<bool>('isFocus') as SMIBool?;
    _isPrivateField = _controller.findInput<bool>('isPrivateField') as SMIBool?;
    _numLook = _controller.findInput<double>('numLook') as SMINumber?;
    _successTrigger = _controller.findInput<bool>('successTrigger') as SMITrigger?;
    _failTrigger = _controller.findInput<bool>('failTrigger') as SMITrigger?;
  }

  /// Set to `true` when the user focuses the phone/email field.
  /// The bear looks down at the text field.
  set isChecking(bool value) => _isFocus?.value = value;

  /// Set to `true` when the user focuses the OTP/password field.
  /// The bear covers its eyes with its paws.
  set isHandsUp(bool value) => _isPrivateField?.value = value;

  /// Controls the bear's eye tracking direction.
  /// Values typically range from 0 (looking left) to 100 (looking right).
  set look(double value) => _numLook?.value = value;

  /// Fire the happy celebration animation (e.g., on successful OTP send).
  void triggerSuccess() => _successTrigger?.fire();

  /// Fire the sad/shake animation (e.g., on verification failure).
  void triggerFail() => _failTrigger?.fire();

  /// Dispose the underlying state machine controller.
  void dispose() => _controller.dispose();
}
