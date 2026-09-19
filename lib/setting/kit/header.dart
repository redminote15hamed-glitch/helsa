// فایل: lib/setting/kit/header.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart'; // 👈 اضافه شدن اکستنشن ریسپانسیو شما

class Header extends StatelessWidget {
  final Widget? leftChild;
  final Widget? centerChild;
  final Widget? rightChild;
  final int leftFlex;
  final int centerFlex;
  final int rightFlex;

  const Header({
    super.key,
    this.leftChild,
    this.centerChild,
    this.rightChild,
    this.leftFlex = 1,
    this.centerFlex = 4,
    this.rightFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // بخش چپ (دکمه بازگشت و ...)
          Expanded(
            flex: leftFlex,
            child: leftChild ?? const SizedBox.shrink(),
          ),

          // بخش وسط (عناوین، پروگرس بار و ...)
          Expanded(
            flex: centerFlex,
            child: centerChild ?? const SizedBox.shrink(),
          ),

          // بخش راست (دکمه پشتیبانی و ...)
          Expanded(
            flex: rightFlex,
            child: rightChild ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
