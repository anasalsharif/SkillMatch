import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/file_uploader.dart';
import 'file_uploader_interface.dart';

final FileUploaderInterface fileUploader = WebFileUploader();

Future<void> uploadFile(String token) async {
  final fileBytes = await fileUploader.pickFile();
  if (fileBytes != null) {
    final result = await fileUploader.uploadFile(fileBytes, token);
    // handle result
  }
}
