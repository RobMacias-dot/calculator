import 'package:flutter/widgets.dart';

/// Flutter exposes Apple's Reduce Motion separately from disableAnimations.
/// Honor both; the animated pilot also observes runtime accessibility changes.
bool reduceVisualMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    View.of(context)
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations ||
    View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
