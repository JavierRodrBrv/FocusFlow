import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PremiumLoader extends StatelessWidget {
  final double size;
  final String animationPath;
  final Color? color;

  const PremiumLoader({
    super.key,
    this.size = 120.0,
    this.animationPath = 'assets/json/carga_logo.json',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          animationPath,
          fit: BoxFit.contain,
          delegates: LottieDelegates(
            values: color != null
                ? [
                    ValueDelegate.color(
                      const ['**'],
                      value: color,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
