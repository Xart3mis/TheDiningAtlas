import 'dart:io';
import '../interfaces/i_storage_service.dart';

class MockStorageService implements IStorageService {
  @override
  Future<String> uploadImage({required File file, required String path}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://placeholder.com/mock-image.jpg';
  }

  @override
  Future<void> deleteFile(String url) async {}
}
