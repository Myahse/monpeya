import 'dart:io';

import 'package:image/image.dart' as img;

/// Generates Android `mipmap-night-*` launcher icons from the dark theme asset.
void main() {
  const sourcePath = 'assets/logo/app-icons/mon peya-dark.png';
  const sizes = <String, int>{
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing dark icon: $sourcePath');
    exit(1);
  }

  final decoded = img.decodePng(sourceFile.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode PNG: $sourcePath');
    exit(1);
  }

  for (final entry in sizes.entries) {
    final dir = Directory('android/app/src/main/res/mipmap-night-${entry.key}');
    dir.createSync(recursive: true);
    final resized = img.copyResize(
      decoded,
      width: entry.value,
      height: entry.value,
      interpolation: img.Interpolation.average,
    );
    File('${dir.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(resized));
  }

  stdout.writeln('Android night launcher icons written to mipmap-night-*');
}
