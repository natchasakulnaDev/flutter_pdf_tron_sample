import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pdftron_flutter/pdftron_flutter.dart';

import 'common/file_helper.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _version = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  openFile() async {
    String tmpPath;
    File newFile;
    Pair<File, File> backupFile;
    int id = 1;
    String folderName = '1_1';
    String fileName = 'pdfref.pdf';
    bool isEdit = false;
    FileHelper fileHelper = FileHelper();
    String path = "https://pdftron.s3.amazonaws.com/downloads/pdfref.pdf";
    fileHelper.init();

    await fileHelper.getFileFromUrl(id, path, folderName, name: fileName).then(
      (value) {
        tmpPath = value.path;
      },
    );


    await PdftronFlutter.openDocument(tmpPath, config: fileHelper.initialConfigPdfTron());

    startExportAnnotationCommandListener(
      (_) async {
        backupFile = await fileHelper.getBackupFile(
          id.toString(),
          tmpPath,
          folderName,
        );


        if (backupFile != null) {
          String document = await PdftronFlutter.saveDocument();
          if (!isEdit) {
            isEdit = true;
            Future.delayed(
              Duration(seconds: 1),
              () async {
                newFile = await fileHelper.getNewFile(
                  id.toString(),
                  document,
                  folderName,
                );
                await fileHelper.replaceBackupFile(
                  id.toString(),
                  backupFile.first,
                  backupFile.second,
                  folderName,
                );
              },
            );
          }
        }
      },
    );
  }

  Future<void> initPlatformState() async {
    String version;

    try {
      version = await PdftronFlutter.version;
    } on PlatformException {
      version = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _version = version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PDFTron flutter app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('Running on: $_version\n'),
              RaisedButton(
                child: Text('Open File'),
                onPressed: () {
                  openFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
