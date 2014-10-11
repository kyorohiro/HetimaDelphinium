library delphiniumapp;
import 'dart:html' as html;
import 'dart:convert' as convert;
import 'dart:async' as async;
import 'dart:typed_data' as typed_data;
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetima/hetima.dart' as hetima;
import 'package:hetima/hetima_cl.dart' as hetimacl;

import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/text.dart' as text;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;
import 'package:dart_web_toolkit/validation.dart' as validation;
import 'package:crypto/crypto.dart' as crypt;
part 'mainpanel.dart';
part 'filelistpanel.dart';
part 'mainview.dart';
part 'httpserver.dart';
part 'portmap.dart';
part 'infopanel.dart';


void main() {
  String downloadPath = "hetima";
  MainView mainView = new MainView();
  mainView.downloadPath = downloadPath;
  HttpServer httpServer = new HttpServer();
  httpServer.dataPath = downloadPath;
  PortMap portMap = new PortMap();

  httpServer.onUpdateLocalServer.listen((String localPort){
    mainView.localPort = localPort;
    portMap.localPort = int.parse(localPort);
  });
  portMap.onUpdateGlobalIp.listen((String globalIp) {
    mainView.globalIP = globalIp;
  });
  portMap.onUpdateGlobalPort.listen((String globalPort) {
    mainView.globalPort = globalPort;
  });
  portMap.onUpdateLocalIp.listen((String localIP) {
    mainView.localIP = localIP;
  });

  mainView.onChRootPath.listen((String path){
    httpServer.localIP = path;
    mainView.downloadPath = path;
  });

  mainView.onInitAddress.listen((String ip) {
    httpServer.localIP = ip;    
  });
  mainView.init();
  mainView.onChangeMainButtonState.listen((bool isDown) {
    if (isDown) {
      httpServer.startServer().then((int v) {
        return portMap.startGetLocalIp();
      }).then((int v) {
        portMap.startPortMap();
      });
    } else {
      httpServer.stopServer();
      portMap.deleteAllPortMap();
    }
  });

  mainView.onSelectFile.listen((FileSelectResult result) {
    String label = "${result.fname}";
    httpServer.addFile(label, result);
    mainView.addFile(label);
  });

  mainView.onDeleteFileFromList.listen((String fname) {
    httpServer.removeFile(fname);
  });

  chrome.app.window.current().onClosed.listen((d) {
    portMap.deleteAllPortMap();
    httpServer.stopServer();
  });
}

