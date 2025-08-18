import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'src/core/config/locator.dart';
import 'src/jet_vpn_app.dart';

final Logger logger = Logger();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Locator.initialize();
  runApp(const JetVpnApp());
}