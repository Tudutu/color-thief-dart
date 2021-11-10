import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'quantize_null_safe.dart';

_createPixelArray(Uint8List imgData, int pixelCount, int quality) {
  final pixels = imgData;
  List<List<int>> pixelArray = [];
  int offset, r, g, b;
  int? a;
  for (var i = 0; i < pixelCount; i = i + quality) {
    offset = i * 4;
    r = pixels[offset + 0];
    g = pixels[offset + 1];
    b = pixels[offset + 2];
    a = pixels[offset + 3];

    if (a == null || a >= 125) {
      if (!(r > 250 && g > 250 && b > 250)) {
        pixelArray.add([r, g, b]);
      }
    }
  }
  return pixelArray;
}

List<int> _validateOptions(int? colorCount, int? quality) {
  if (colorCount == null || colorCount.runtimeType != int) {
    colorCount = 10;
  } else {
    colorCount = max(colorCount, 2);
    colorCount = min(colorCount, 20);
  }
  if (quality == null || quality.runtimeType != int) {
    quality = 10;
  } else if (quality < 1) {
    quality = 10;
  }
  return [colorCount, quality];
}

Future<List<List<int>>?> getPaletteFromBytes(
    Uint8List imageData, int width, int height,
    [int? colorCount, int? quality]) async {
  final options = _validateOptions(colorCount, quality);
  colorCount = options[0];
  quality = options[1];

  final pixelCount = width * height;

  final pixelArray = _createPixelArray(imageData, pixelCount, quality);

  final cmap = quantize(pixelArray, colorCount);
  final palette = cmap?.palette();

  return palette;
}

/// returns a list that contains the reduced color palette, represented as [[R,G,B]]
///
/// `image` - Image
///
/// `colorCount` - Between 2 and 256. The maximum number of colours allowed in the reduced palette
///
/// `quality` - Between 1 and 10. There is a trade-off between quality and speed. The bigger the number, the faster the palette generation but the greater the likelihood that colors will be missed.
Future<List<List<int>>?> getPaletteFromImage(Image image,
    [int? colorCount, int? quality]) async {
  final options = _validateOptions(colorCount, quality);
  colorCount = options[0];
  quality = options[1];

  final imageData = await image
      .toByteData(format: ImageByteFormat.rawRgba)
      .then((val) => Uint8List.view((val!.buffer)));
  return getPaletteFromBytes(
      imageData, image.width, image.height, colorCount, quality);
}

/// returns the base color from the largest cluster, represented as [R,G,B]
///
/// `image` - Image
///
/// `quality` - Between 1 and 10. There is a trade-off between quality and speed. The bigger the number, the faster the palette generation but the greater the likelihood that colors will be missed.
Future<List<int>?> getColorFromImage(Image image, [int quality = 10]) async {
  final palette = await getPaletteFromImage(image, 5, quality);
  if (palette == null) {
    return null;
  }
  final dominantColor = palette[0];
  return dominantColor;
}
