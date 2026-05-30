import 'package:flutter/material.dart';
import '../constants/colors.dart';

class KeprLogo extends StatelessWidget {
  final double size;
  final bool rounded;

  const KeprLogo({
    Key? key,
    this.size = 48,
    this.rounded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(rounded ? 10 : 0),
      child: Image.asset(
        'assets/brand/kepr_lockup.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class KeprBrandMark extends StatelessWidget {
  final double height;
  final Color textColor;

  const KeprBrandMark({
    Key? key,
    this.height = 42,
    this.textColor = AppColors.crimson,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeprLogo(size: height),
        const SizedBox(width: 10),
        Text(
          'Kepr',
          style: TextStyle(
            color: textColor,
            fontSize: height * 0.55,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
