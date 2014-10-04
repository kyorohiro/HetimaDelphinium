library delphiniumapp;
import 'dart:html' as html;
import 'dart:convert' as convert;
import 'dart:async' as async;

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

part 'mainpanel.dart';
part 'filelistpanel.dart';
part 'mainview.dart';
part 'httpserver.dart';
part 'portmap.dart';


void main() {
  MainView m = new MainView();
  HttpServer httpServer = new HttpServer();
  PortMap portMap = new PortMap();

  httpServer.onUpdateLocalServer.listen((String localPort){
    m.localPort = localPort;
    portMap.localPort = int.parse(localPort);
  });
  portMap.onUpdateGlobalIp.listen((String globalIp) {
    m.globalIP = globalIp;
  });
  portMap.onUpdateGlobalPort.listen((String globalPort) {
    m.globalPort = globalPort;
  });
  portMap.onUpdateLocalIp.listen((String localIP) {
    m.localIP = localIP;
  });

  m.init();
  m.onChangeMainButtonState.listen((bool isDown) {
    if (isDown) {
      httpServer.startServer().then((int v) {
        return portMap.startLocalIp();
      }).then((int v) {
        portMap.startPortMap();
      });
    } else {
      httpServer.stopServer();
      portMap.deleteAllPortMap();
    }
  });
  int id = 0;
  m.onSelectFile.listen((FileSelectResult result) {
    String label = "${id++}_${result.fname}";
    httpServer.publicFileList[label] = result;
    m.addFile(label);
  });

  m.onDeleteFileFromList.listen((String fname) {
    httpServer.publicFileList.remove(fname);
  });
  chrome.app.window.current().onClosed.listen((d) {
    portMap.deleteAllPortMap();
    httpServer.stopServer();
  });
}

