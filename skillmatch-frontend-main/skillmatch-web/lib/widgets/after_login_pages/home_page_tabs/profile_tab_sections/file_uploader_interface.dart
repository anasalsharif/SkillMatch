import 'dart:typed_data';

abstract class FileUploaderInterface {
  Future<Uint8List?> pickFile();
  Future<String?> uploadFile(Uint8List fileBytes, String token);
}
