import 'dart:async';
import 'dart:typed_data';
import 'image_picker_interface.dart';

// This file will only be used on web platform
import 'dart:html' as html;

class WebImagePickerWeb implements ImagePickerInterface {
  @override
  Future<Uint8List?> pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    final completer = Completer<Uint8List?>();

    input.onChange.listen((event) {
      if (input.files?.isNotEmpty ?? false) {
        final file = input.files!.first;
        final reader = html.FileReader();

        reader.onLoad.listen((event) {
          final bytes = reader.result as List<int>;
          completer.complete(Uint8List.fromList(bytes));
        });

        reader.onError.listen((event) {
          completer.complete(null);
        });

        reader.readAsArrayBuffer(file);
      } else {
        completer.complete(null);
      }
    });

    return completer.future;
  }
}
