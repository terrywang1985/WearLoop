import 'dart:io';

import 'package:flutter/material.dart';

Widget localFileImage(
  String path, {
  required BoxFit fit,
  required Widget fallback,
}) =>
    Image.file(
      File(path),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
    );
