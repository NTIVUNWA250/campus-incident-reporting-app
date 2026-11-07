import 'dart:typed_data';

String photoContentType(Uint8List bytes) {
  if (bytes.length > 5 * 1024 * 1024) {
    throw StateError('Choose a photo smaller than 5 MB.');
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  const png = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length >= 8 &&
      List.generate(8, (i) => bytes[i] == png[i]).every((v) => v)) {
    return 'image/png';
  }
  throw StateError('Choose a JPEG or PNG photo.');
}
