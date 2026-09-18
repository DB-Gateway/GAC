import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/index.dart';

void main() {
  testWidgets('moving white wordmark has no dark matte or crop outline', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final boundaryKey = GlobalKey();

    for (final background in const [Color(0xFF17395B), Color(0xFFB6A483)]) {
      for (final width in [129.25, 161.27, 200.0]) {
        for (final progress in [0.0, 0.15, 0.35, 0.6, 0.72, 0.85, 0.99, 1.0]) {
          await tester.pumpWidget(
            MaterialApp(
              home: RepaintBoundary(
                key: boundaryKey,
                child: ColoredBox(
                  color: background,
                  child: Center(
                    child: GatewayExpandingWordmark(
                      width: width,
                      progress: progress,
                    ),
                  ),
                ),
              ),
            ),
          );
          for (var attempt = 0; attempt < 50; attempt++) {
            if (tester.widget<RawImage>(find.byType(RawImage).first).image !=
                null) {
              break;
            }
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump();
          }
          expect(
            tester.widget<RawImage>(find.byType(RawImage).first).image,
            isNotNull,
            reason: 'The transparent logo must finish decoding.',
          );
          await tester.pump();

          for (final pixelRatio in [1.0, 2.75]) {
            await tester.runAsync(() async {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final frame = await boundary.toImage(pixelRatio: pixelRatio);
              try {
                final data = (await frame.toByteData())!;
                final rgb = [
                  (background.r * 255).round(),
                  (background.g * 255).round(),
                  (background.b * 255).round(),
                ];
                var darkPixels = 0;
                var visiblePixels = 0;
                for (var offset = 0; offset < data.lengthInBytes; offset += 4) {
                  if (data.getUint8(offset) < rgb[0] - 1 ||
                      data.getUint8(offset + 1) < rgb[1] - 1 ||
                      data.getUint8(offset + 2) < rgb[2] - 1) {
                    darkPixels++;
                  }
                  if (data.getUint8(offset) > rgb[0] + 20) visiblePixels++;
                }
                expect(
                  darkPixels,
                  0,
                  reason:
                      'Dark edge at p=$progress, width=$width, DPR=$pixelRatio',
                );
                expect(
                  visiblePixels,
                  greaterThan(20),
                  reason: 'The logo must remain visible, not just transparent.',
                );
              } finally {
                frame.dispose();
              }
            });
          }
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('circle fade uses clean ink edges and finishes without a jump', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 320);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final boundaryKey = GlobalKey();
    Future<ByteData> render(double chrome) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: const Color(0xFF17395B),
              child: Center(
                child: GatewayLogoBadge(
                  size: 300,
                  imageScale: 0.82,
                  expansionProgress: 1,
                  chromeOpacity: chrome,
                ),
              ),
            ),
          ),
        ),
      );
      for (var attempt = 0; attempt < 50; attempt++) {
        final images = tester.widgetList<RawImage>(find.byType(RawImage));
        if (images.isNotEmpty && images.every((image) => image.image != null)) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .every((image) => image.image != null),
        isTrue,
      );
      await tester.pump();
      return (await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        try {
          return await image.toByteData();
        } finally {
          image.dispose();
        }
      }))!;
    }

    final midpoint = await render(0.5);
    // Halfway through the fade the single wordmark is neutral gray. Its
    // antialiased edges must blend into the lighter disc without a dark rim.
    var grayInkPixels = 0;
    var darkEdgePixels = 0;
    for (var y = 152; y < 168; y++) {
      for (var x = 80; x < 241; x++) {
        final offset = (y * 320 + x) * 4;
        final r = midpoint.getUint8(offset);
        final g = midpoint.getUint8(offset + 1);
        final b = midpoint.getUint8(offset + 2);
        if (r < 126 || g < 126 || b < 126) darkEdgePixels++;
        if ((r - 128).abs() <= 1 &&
            (g - 128).abs() <= 1 &&
            (b - 128).abs() <= 1) {
          grayInkPixels++;
        }
      }
    }
    expect(grayInkPixels, greaterThan(150));
    expect(darkEdgePixels, 0);

    final before = await render(0.99999);
    final after = await render(1);
    var difference = 0;
    for (var offset = 0; offset < before.lengthInBytes; offset += 4) {
      for (var channel = 0; channel < 3; channel++) {
        difference +=
            (before.getUint8(offset + channel) -
                    after.getUint8(offset + channel))
                .abs();
      }
    }
    expect(
      difference / (320 * 320 * 3),
      lessThan(0.15),
      reason:
          'The final circle must keep the wordmark in exactly the same place.',
    );
    expect(tester.takeException(), isNull);
  });
}
