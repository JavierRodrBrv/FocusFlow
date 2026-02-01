import 'package:flutter/material.dart';
import 'app.dart';
import 'flavors.dart';
import 'bootstrap.dart';

void main() async {
  F.appFlavor = Flavor.pro;
  await bootstrap();
  runApp(const App());
}
