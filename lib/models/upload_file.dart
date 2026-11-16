import 'dart:typed_data';

class UploadFile {
  final String key;
  final String label;
  final Uint8List bytes;

  const UploadFile(this.key, this.label, this.bytes);
}