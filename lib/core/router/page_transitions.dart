import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Durasi & kurva animasi standar aplikasi.
class AppTransitions {
  static const Duration duration = Duration(milliseconds: 380);
  static const Duration loginDuration = Duration(milliseconds: 450);
  static const Curve curve = Curves.easeInOutCubic;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Transisi lembut untuk pergantian menu utama (fade + slide halus).
  static CustomTransitionPage<T> fadeSlide<T>({
    required GoRouterState state,
    required Widget child,
    Offset slideBegin = const Offset(0.015, 0),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: enterCurve,
          reverseCurve: exitCurve,
        );
        final fade = Tween<double>(begin: 0, end: 1).animate(curved);
        final slide = Tween<Offset>(
          begin: slideBegin,
          end: Offset.zero,
        ).animate(curved);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  /// Transisi login / logout.
  static CustomTransitionPage<T> fade<T>({
    required GoRouterState state,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration ?? loginDuration,
      reverseTransitionDuration: duration ?? loginDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
    );
  }

  /// Detail barang — slide dari kanan (stack navigation).
  static CustomTransitionPage<T> slideFromRight<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: enterCurve,
          reverseCurve: exitCurve,
        );
        final offset = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curved);

        return FadeTransition(
          opacity: Tween<double>(begin: 0.85, end: 1).animate(curved),
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }
}
