import 'package:flutter/foundation.dart' show kIsWeb;
import 'image_picker_interface.dart';
import 'mobile_image_picker.dart';
import 'web_image_picker_stub.dart'
    if (dart.library.html) 'web_image_picker_web.dart';

ImagePickerInterface get WebImagePicker =>
    kIsWeb ? WebImagePickerWeb() : MobileImagePicker();
