import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';
import 'file_uploader_interface.dart';

class WebFileUploader implements FileUploaderInterface {
  @override
  Future<Uint8List?> pickFile() async {
    final input = html.FileUploadInputElement()..accept = '.pdf,.doc,.docx';
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

  @override
  Future<String?> uploadFile(Uint8List fileBytes, String token) async {
    try {
      final uri = Uri.parse(
        'https://talentlink-api.onrender.com/users/upload-cv',
      );

      final formData = html.FormData();
      final blob = html.Blob([fileBytes]);
      formData.appendBlob('file', blob);

      final request = html.HttpRequest();
      request.open('POST', uri.toString());
      request.setRequestHeader('Authorization', 'Bearer $token');

      final completer = Completer<String?>();

      request.onLoad.listen((event) {
        if (request.status == 200) {
          completer.complete(request.responseText);
        } else {
          print('Upload failed: ${request.status} - ${request.responseText}');
          completer.complete(null);
        }
      });

      request.onError.listen((event) {
        print('Error uploading file: $event');
        completer.complete(null);
      });

      request.send(formData);

      return await completer.future;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
}
