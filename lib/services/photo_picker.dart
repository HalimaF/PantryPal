import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// A photo, small enough to send quickly.
class PickedPhoto {
  const PickedPhoto(this.bytes, this.mimeType);

  final Uint8List bytes;
  final String mimeType;
}

enum PhotoSource { camera, gallery }

/// Opens the camera or the gallery. Replaceable in tests, which have neither.
typedef PhotoPicker = Future<PickedPhoto?> Function(PhotoSource source);

/// Returns null when she backs out without choosing anything.
Future<PickedPhoto?> pickPhotoFromDevice(PhotoSource source) async {
  final file = await ImagePicker().pickImage(
    source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
    // Shrunk on the phone, so the upload is quick and uses little of the free allowance.
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final name = file.path.toLowerCase();
  final mime = name.endsWith('.png') ? 'image/png' : 'image/jpeg';
  return PickedPhoto(bytes, mime);
}
