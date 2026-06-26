import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

Future<String?> uploadVideoFileFromPath(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) return null;
  final fileBytes = await file.readAsBytes();
  final fileName = file.uri.pathSegments.last;
  final path = 'videos/  ${DateTime.now().millisecondsSinceEpoch}_$fileName';
  final ref = FirebaseStorage.instance.ref().child(path);
  final uploadTask = ref.putData(fileBytes);
  final snapshot = await uploadTask.whenComplete(() {});
  final url = await snapshot.ref.getDownloadURL();
  return url;
}
