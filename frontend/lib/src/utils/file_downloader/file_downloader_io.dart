import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<String?> downloadAndSaveFile(List<int> bytes, String fileName) async {
  Directory? directory;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    directory = await getDownloadsDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  if (directory == null) return null;

  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  await OpenFile.open(filePath);
  return filePath;
}
