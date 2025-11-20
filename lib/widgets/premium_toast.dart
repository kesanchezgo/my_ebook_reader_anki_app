import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumToast {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, String message, {bool isError = false, bool isSuccess = false, bool isWarning = false}) {
    // Remove existing toast if present
    if (_currentEntry != null) {
      try {
        _currentEntry!.remove();
      } catch (e) {
        // Ignore if already removed
      }
      _currentEntry = null;
    }

    final overlayState = Overlay.of(context);
    
    _currentEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isError: isError,
        isSuccess: isSuccess,
        isWarning: isWarning,
        onDismiss: () {
          if (_currentEntry != null) {
            try {
              _currentEntry!.remove();
            } catch (e) {
              // Ignore
            }
            _currentEntry = null;
          }
        },
      ),
    );

    overlayState.insert(_currentEntry!);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isSuccess;
  final bool isWarning;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.isSuccess,
    required this.isWarning,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    Color iconColor;

    if (widget.isError) {
      backgroundColor = isDark ? const Color(0xFFCF6679) : const Color(0xFFB00020);
      textColor = Colors.white;
      icon = Icons.error_outline_rounded;
      iconColor = Colors.white;
    } else if (widget.isSuccess) {
      backgroundColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF018786);
      textColor = isDark ? Colors.black : Colors.white;
      icon = Icons.check_circle_outline_rounded;
      iconColor = isDark ? Colors.black : Colors.white;
    } else if (widget.isWarning) {
      backgroundColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
      textColor = isDark ? Colors.black : Colors.white;
      icon = Icons.warning_amber_rounded;
      iconColor = isDark ? Colors.black : Colors.white;
    } else {
      // Default / Info
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurface;
      icon = Icons.info_outline_rounded;
      iconColor = theme.colorScheme.primary;
    }

    return Positioned(
      bottom: 50 + bottomPadding,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.95), // Slightly more opaque for overlay
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: iconColor, size: 22),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
