import 'package:flutter/material.dart';

/// This class provides a way to synchronize multiple ScrollControllers.
/// It creates and manages a group of ScrollControllers that mirror each other's scroll position.
class LinkedScrollControllerGroup {
  LinkedScrollControllerGroup() {
    _offsetNotifier = _LinkedScrollControllerGroupOffsetNotifier(this);
  }

  final _controllers = <_LinkedScrollController>[];
  _LinkedScrollControllerGroupOffsetNotifier? _offsetNotifier;

  /// The current scroll offset of the group.
  double get offset => _offsetNotifier!.value;

  /// Creates a new ScrollController that is linked to this group.
  ScrollController addAndGet() {
    final controller = _LinkedScrollController(this);
    _controllers.add(controller);
    controller._attach(this);
    return controller;
  }

  /// Disposes the group and all controllers in it.
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _offsetNotifier!.dispose();
    _offsetNotifier = null;
  }

  /// Called by the linked controllers when they are scrolled.
  /// Updates all other controllers in the group.
  void _updateGroup(double newOffset, _LinkedScrollController origin) {
    _offsetNotifier!.value = newOffset;
    for (final controller in _controllers) {
      if (controller != origin) {
        controller._jumpTo(newOffset);
      }
    }
  }
}

/// A ScrollController that is linked to a [LinkedScrollControllerGroup].
class _LinkedScrollController extends ScrollController {
  _LinkedScrollController(this._group);

  final LinkedScrollControllerGroup _group;
  bool _isAttached = false;
  double _lastScrollOffset = 0.0;

  /// Attaches this controller to the group.
  void _attach(LinkedScrollControllerGroup group) {
    _isAttached = true;
    if (positions.isNotEmpty) {
      _lastScrollOffset = position.pixels;
      _group._updateGroup(_lastScrollOffset, this);
    }
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    if (_isAttached) {
      position.correctPixels(_lastScrollOffset);
      _group._updateGroup(_lastScrollOffset, this);
    }
  }

  @override
  void detach(ScrollPosition position) {
    _lastScrollOffset = position.pixels;
    super.detach(position);
  }

  @override
  void dispose() {
    _isAttached = false;
    super.dispose();
  }

  /// Jumps to the given offset without animation.
  void _jumpTo(double value) {
    if (positions.isNotEmpty && position.pixels != value) {
      position.correctPixels(value);
    } else {
      _lastScrollOffset = value;
    }
  }

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    _group._updateGroup(offset, this);
    return super.animateTo(
      offset,
      duration: duration,
      curve: curve,
    );
  }

  @override
  void jumpTo(double value) {
    _group._updateGroup(value, this);
    super.jumpTo(value);
  }
}

/// A ValueNotifier that notifies listeners when the scroll offset changes.
class _LinkedScrollControllerGroupOffsetNotifier extends ValueNotifier<double> {
  _LinkedScrollControllerGroupOffsetNotifier(this.group) : super(0.0);

  final LinkedScrollControllerGroup group;
}
