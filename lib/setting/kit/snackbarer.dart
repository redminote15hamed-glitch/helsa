// فایل: lib/setting/kit/snackbarer.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textfielder.dart';

enum SnackbarTemplate {
  neutral, // تمپلیت هماهنگ با دکمه‌های زبانی primary غیرانتخابی
  caution, // تمپلیت اخطار با پس‌زمینه قرمز و متن سفید
  flatOnSurface, // تمپلیت با رنگ روی سطح و متن معکوس
}

class SnackBarer {
  // 👈 ذخیره زمان آخرین باری که اسنک‌بار با موفقیت نمایش داده شد
  static DateTime? _lastShownTime;
  static OverlayEntry? _currentOverlayEntry;

  static void show(
    BuildContext context, {
    required String message,
    required SnackbarTemplate template,
    Duration duration = const Duration(seconds: 3),
  }) {
    final now = DateTime.now();

    // 👈 بررسی اینکه آیا اسنک‌بار فعال است و از نمایش آخرین اسنک‌بار کمتر از ۴ ثانیه می‌گذرد؟
    if (_lastShownTime != null &&
        now.difference(_lastShownTime!) < const Duration(seconds: 4)) {
      return; // اگر کمتر از ۴ ثانیه گذشته باشد، کلیک جدید نادیده گرفته می‌شود
    }

    // به‌روزرسانی زمان آخرین نمایش موفق
    _lastShownTime = now;

    final theme = Theme.of(context);

    // حذف اسنک‌بار قبلی جهت جلوگیری از تداخل انیمیشن‌ها
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;

    // متغیرهای استایل‌دهی داینامیک
    late Color bg;
    late Color textColor;
    Border? customBorder;
    final double radius = context.l;

    // ماتریس استایل بر اساس تمپلیت انتخابی
    switch (template) {
      case SnackbarTemplate.neutral:
        bg = theme.colorScheme.surface;
        textColor = theme.colorScheme.primary;
        customBorder = Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 0.8,
        );
        break;
      case SnackbarTemplate.caution:
        bg = Colors.red.shade600;
        textColor = Colors.white;
        customBorder = null;
        break;
      case SnackbarTemplate.flatOnSurface:
        bg = theme.colorScheme.onSurface;
        textColor = theme.colorScheme.surface;
        customBorder = null;
        break;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    final overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.viewPaddingOf(context).top + context.vM * 0.7,
          left: context.screenWidth * 0.02,
          right: context.screenWidth * 0.02,
          child: SafeArea(
            bottom: false,
            child: _SnackBarAnimationWrapper(
              duration: duration,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  alignment: Alignment.center,
                  height: context.vM,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(radius),
                    border: customBorder,
                  ),
                  child: TextFielder(
                    text: message,
                    template: TextTemplate.button,
                    textAlign: TextAlign.center,
                    customStyle: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentOverlayEntry = overlayEntry;
    overlay.insert(overlayEntry);

    Future.delayed(duration + const Duration(milliseconds: 300), () {
      if (_currentOverlayEntry == overlayEntry) {
        _currentOverlayEntry = null;
      }
      overlayEntry.remove();
    });
  }
}

/// مدیریت انیمیشن اسلاید ورودی (Slide Down) و خروجی (Slide Up) بر اساس چرخه‌عمر اسنک‌بار
class _SnackBarAnimationWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _SnackBarAnimationWrapper({
    required this.child,
    required this.duration,
  });

  @override
  State<_SnackBarAnimationWrapper> createState() =>
      _SnackBarAnimationWrapperState();
}

class _SnackBarAnimationWrapperState extends State<_SnackBarAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();

    final int exitDelay = widget.duration.inMilliseconds - 300;
    if (exitDelay > 0) {
      Future.delayed(Duration(milliseconds: exitDelay), () {
        if (mounted) {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}
