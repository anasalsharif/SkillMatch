import 'dart:typed_data';
import 'image_picker_interface.dart';

class WebImagePickerWeb implements ImagePickerInterface {
  @override
  Future<Uint8List?> pickImage() async {
    // This is a stub implementation that will never be called
    // The actual implementation will be provided by mobile_image_picker.dart
    throw UnsupportedError(
      'Web image picker is not supported on this platform',
    );
  }
}
