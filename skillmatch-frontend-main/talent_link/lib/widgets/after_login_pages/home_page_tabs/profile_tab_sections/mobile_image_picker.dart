import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'image_picker_interface.dart';

class MobileImagePicker implements ImagePickerInterface {
  final _picker = ImagePicker();

  @override
  Future<Uint8List?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return await image.readAsBytes();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }
}
