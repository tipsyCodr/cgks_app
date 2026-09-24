import 'package:flutter/material.dart';

class CurvedBody extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double radius;

  const CurvedBody({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
