import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PremiumLoader extends StatelessWidget {
  final double size;

  const PremiumLoader({
    super.key,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          'assets/json/carga_logo.json',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
