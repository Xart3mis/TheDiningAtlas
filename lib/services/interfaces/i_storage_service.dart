import 'dart:io';

abstract class IStorageService {
  Future<String> uploadImage({required File file, required String path});
  Future<void> deleteFile(String url);
}
