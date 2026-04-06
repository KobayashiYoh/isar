// ignore_for_file: avoid_web_libraries_in_flutter, implementation_imports

import 'dart:js_interop';

import 'package:isar/src/web/open.dart' as isar_web;
import 'package:isar_test/src/isar_web_src.dart';

@JS('eval')
external void _eval(String code);

Future<void> init() async {
  _eval(isarWebSrc);
  // ignore: invalid_use_of_visible_for_testing_member
  isar_web.doNotInitializeIsarWeb();
}
