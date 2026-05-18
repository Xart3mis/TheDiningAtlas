import 'dart:io';

abstract class IStorageService {
  Future<String> uploadImage({required String filePath, required String storagePath});
  Future<void> deleteFile(String url);
}
