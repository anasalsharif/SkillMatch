import 'dart:typed_data';
import 'file_uploader_interface.dart';

class WebFileUploader implements FileUploaderInterface {
  @override
  Future<Uint8List?> pickFile() async {
    throw UnsupportedError(
      'Web file uploader is not supported on this platform',
    );
  }

  @override
  Future<String?> uploadFile(Uint8List fileBytes, String token) async {
    throw UnsupportedError(
      'Web file uploader is not supported on this platform',
    );
  }
}
