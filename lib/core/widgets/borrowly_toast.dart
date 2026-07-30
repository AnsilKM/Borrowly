import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Top-floating Toast banner component for Borrowly
class BorrowlyToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final topPadding = MediaQuery.of(context).viewPadding.top;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _TopToastWidget(
          message: message,
          isError: isError,
          icon: icon,
          topPadding: topPadding > 0 ? topPadding + 10 : 28,
          onDismissed: () {
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
            }
          },
          duration: duration,
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final IconData? icon;
  final double topPadding;
  final VoidCallback onDismissed;
  final Duration duration;

  const _TopToastWidget({
    required this.message,
    required this.isError,
    this.icon,
    required this.topPadding,
    required this.onDismissed,
    required this.duration,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding,
      left: 45,
      right: 45,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: widget.isError ? AppColors.danger : AppColors.textPrimary,
                borderRadius: AppRadii.borderPill,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon ?? (widget.isError ? Icons.error_outline_rounded : Icons.info_outline_rounded),
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
