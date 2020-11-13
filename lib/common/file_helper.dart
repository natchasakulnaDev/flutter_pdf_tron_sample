import 'dart:io' as io;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdftron_flutter/pdftron_flutter.dart';
import 'package:http/http.dart' as http;

class Pair<F extends dynamic, S extends dynamic> {
  F first;
  S second;

  Pair(this.first, this.second);

  @override
  String toString() {
    return 'Pair{(${first.runtimeType}) $first, (${second.runtimeType}) $second}';
  }
}

extension ListUtil on List {
  E firstOrNull<E>() {
    return this == null || this.isEmpty ? null : this.first;
  }

  bool get isNotBlank => this != null && this.isNotEmpty;
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
    <K, List<E>>{},
        (Map<K, List<E>> map, E element) =>
    map..putIfAbsent(keyFunction(element), () => <E>[]).add(element),
  );

  Iterable<K> mapIndexed<K>(K Function(E, int) mapFunction) sync* {
    var i = 0;
    for (var item in this) {
      yield mapFunction(item, i++);
    }
  }
}

class FileHelper {
  io.Directory temporaryDirectory;

  init() async {
    temporaryDirectory = await getTemporaryDirectory();
  }

  Config initialConfigPdfTron() {
    var disabledElements = [Buttons.saveCopyButton, Buttons.searchButton];
    var disabledTools = [
      Tools.annotationCreateLine,
      Tools.annotationCreateRectangle
    ];
    var config = Config();
    config.disabledElements = disabledElements;
    config.disabledTools = disabledTools;
    config.customHeaders = {'headerName': 'headerValue'};
    return config;
  }

  Iterable<FileSystemEntity> getTmpFileList(
    String fileName,
    List<FileSystemEntity> fileList,
  ) {
    return fileList
        .where(
          (value) => fileName.contains(
            replaceFileFormat(getFileName(value.path)),
          ),
        )
        .toList();
  }

  FileSystemEntity getTmpFile(
    String fileName,
    List<FileSystemEntity> fileList,
  ) {
    try {
      return fileList.firstWhere((value) => fileName == value.path);
    } catch (e) {
      return null;
    }
  }

  String getFileName(String fileSystemEntity) {
    var splitList = fileSystemEntity.split('/');
    if (splitList.isNotBlank) {
      return splitList.last;
    } else {
      return null;
    }
  }

  Future<List<FileSystemEntity>> getListOfFiles(
      String meetingId, String agendaId) async {
    String directory =
        temporaryDirectory.path + "/" + meetingId + "/" + agendaId + "/";
    return io.Directory(directory)
        .listSync()
        .where((value) => value is io.File)
        .toList();
  }

  Future<File> getFileFromUrl(int meetingId, String url, String agendaId,
      {name}) async {
    var fileName = name;
    try {
      var data = await http.get(url);
      var bytes = data.bodyBytes;
      var mainDir = await io.Directory(
              '${temporaryDirectory.path}/${meetingId.toString()}')
          .create();
      var currentDir =
          await io.Directory('${mainDir.path}/$agendaId/').create();
      File file = File('${currentDir.path}$fileName');
      File urlFile = await file.writeAsBytes(bytes);
      return urlFile;
    } catch (e) {
      throw Exception("Error opening url file");
    }
  }

  Future<Pair<File, File>> getBackupFile(
      String meetingId, String fileName, String agendaId) async {
    List<FileSystemEntity> fileList = await getListOfFiles(meetingId, agendaId);
    var fileSystem = getTmpFile(fileName, fileList);
    File tmpFile = fileSystem;
    File backupFile = await tmpFile.copy(
        '${temporaryDirectory.path}/$meetingId/$agendaId/(backup)${getFileName(fileName)}');
    return Pair(tmpFile, backupFile);
  }

  Future replaceBackupFile(
    String meetingId,
    File originFile,
    File backupFile,
    String agendaId,
  ) async {
    var basePath = '${temporaryDirectory.path}/$meetingId/$agendaId/';
    await backupFile.copy('$basePath${getFileName(originFile.path)}');
//    File localFile = File('$basePath${getFileName(backupFile.path)}');
//    localFile.delete();
  }

  Future<File> getNewFile(
      String meetingId, String fileName, String agendaId) async {
    List<FileSystemEntity> fileList = await getListOfFiles(meetingId, agendaId);
    var fileSystemList = getTmpFileList(fileName, fileList);
    File file = File(fileName);
    String name = getFileName(fileName);
    File tmpFile = file;
    File newFile = await tmpFile.copy(
        '${temporaryDirectory.path}/$meetingId/$agendaId/${getNewFileName(name, fileSystemList.toList().length)}');
    return newFile;
  }

  String getNewFileName(String fileName, int count) {
    RegExp regExp = RegExp(r'(\.pdf|\([0-9]\).pdf)');
    String replaceStr = fileName.replaceAll(regExp, '');
    return '$replaceStr($count).pdf';
  }

  String replaceFileFormat(String fileName) {
    RegExp regExp = RegExp(r'(\.pdf|\([0-9]\).pdf)');
    return fileName.replaceAll(regExp, '').trim();
  }
}
