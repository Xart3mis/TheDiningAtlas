import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../interfaces/i_storage_service.dart';
import '../../core/errors/app_exception.dart';

class FirebaseStorageService implements IStorageService {
  final _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadImage({required File file, required String path}) async {
    try {
      final ref = _storage.ref(path);
      final task = ref.putFile(file);
      int retries = 0;
      while (retries < 3) {
        try {
          await task;
          return await ref.getDownloadURL();
        } catch (_) {
          retries++;
          await Future.delayed(Duration(seconds: retries * 2));
        }
      }
      throw const StorageException();
    } catch (e) {
      throw StorageException(e.toString());
    }
  }

  @override
  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
