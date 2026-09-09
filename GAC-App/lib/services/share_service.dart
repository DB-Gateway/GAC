import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

typedef ShareTextCallback = Future<void> Function(String text);

Future<void> shareText(BuildContext context, String text) async {
  final renderObject = context.findRenderObject();
  final origin = renderObject is RenderBox && renderObject.hasSize
      ? renderObject.localToGlobal(Offset.zero) & renderObject.size
      : null;

  await SharePlus.instance.share(
    ShareParams(text: text, sharePositionOrigin: origin),
  );
}
