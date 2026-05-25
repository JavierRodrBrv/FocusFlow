import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> captureStudyFace() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (photo == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'focus_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = '${directory.path}/$fileName';
      
      final File savedImage = await File(photo.path).copy(targetPath);
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }
}
