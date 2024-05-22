import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart';

class FTPServices {
  Future<void> uploadFileToServer(imagePath, fileName) async {
    final FTPConnect ftpConnect = FTPConnect(
      "ftp.mobileabsensi.pasamanbaratkab.go.id",
      user: "zamal@mobileabsensi.pasamanbaratkab.go.id",
      pass: "zamaladmin12345",
      showLog: true,
    );
    Future<void> log(String log) async {
      await Future.delayed(const Duration(seconds: 1));
    }

    await log('Connecting to FTP ...');
    await ftpConnect.connect();
    await log('Connected to FTP');
    await ftpConnect.changeDirectory('upload');
    File fileToUpload = File(imagePath);
    await log('Uploading ...');
    await ftpConnect.uploadFile(fileToUpload);
    await log('File uploaded successfully');
    await ftpConnect.disconnect();
    await log('Disconnected from FTP');
  }
}
