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

String localAddress = "0.0.0.0";
int externalPort = 18085;

MainView m = new MainView();
HttpServer httpServer = new HttpServer();

void main() {
  httpServer.onUpdateLocalServer.listen((String localPort){
    m.localPort = localPort;
  });
  m.init();
  m.onChangeMainButtonState.listen((bool isDown) {
    if (isDown) {
      httpServer.startServer().then((int v) {
        return startLocalIp();
      }).then((int v) {
        startPortMap();
      });
    } else {
      httpServer.stopServer();
      deleteAllPortMap();
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
    deleteAllPortMap();
    httpServer.stopServer();
  });
}


void startPortMap() {
  hetima.UpnpDeviceSearcher.createInstance(new hetimacl.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
    searcher.searchWanPPPDevice().then((int e) {
      if (searcher.deviceInfoList.length <= 0) {
        return;
      }
      hetima.UPnpDeviceInfo info = searcher.deviceInfoList.first;
      hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
      pppDevice.requestGetExternalIPAddress().then((hetima.UPnpGetExternalIPAddressResponse res) {
        res.externalIp;
        m.globalIP = res.externalIp;
      });
      int baseExternalPort = externalPort + 50;
      a() {
        pppDevice.requestAddPortMapping(externalPort, hetima.UPnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP, httpServer.localPort, localAddress, hetima.UPnpPPPDevice.VALUE_ENABLE, "HetimaDelphinium", 0).then((hetima.UPnpAddPortMappingResponse res) {
          if (200 == res.resultCode) {
            m.globalPort = "${externalPort}";
            return;
          }
          if (-500 == res.resultCode) {
            externalPort++;
            if (externalPort < baseExternalPort) {
              a();
            }
          }
        });
      }
      ;
      a();
    });
  });
}

void deleteAllPortMap() {
  hetima.UpnpDeviceSearcher.createInstance(new hetimacl.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
    searcher.searchWanPPPDevice().then((int e) {
      if (searcher.deviceInfoList.length <= 0) {
        return;
      }
      int index = 0;
      List<int> portList = [];
      b(hetima.UPnpPPPDevice pppDevice) {
        for (int port in portList) {
          pppDevice.requestDeletePortMapping(port, hetima.UPnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP);
        }
      }
      a() {
        hetima.UPnpDeviceInfo info = searcher.deviceInfoList.first;
        hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
        pppDevice.requestGetGenericPortMapping(index++).then((hetima.UPnpGetGenericPortMappingResponse res) {
          if (res.resultCode != 200) {
            b(pppDevice);
            return;
          }
          String description = res.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
          String port = res.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
          String ip = res.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
          if (description == "HetimaDelphinium") {
            int portAsNum = int.parse(port);
            portList.add(portAsNum);
          }
          if (port.replaceAll(" |\t|\r|\n", "") == "" && ip.replaceAll(" |\t|\r|\n", "") == "") {
            b(pppDevice);
            return;
          }
          a();
        });
      }
      a();
    });
  });
}

async.Future<int> startLocalIp() {
  async.Completer<int> completer = new async.Completer();
  (new hetimacl.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> l) {
    // search 24
    for (hetima.HetiNetworkInterface i in l) {
      if (i.prefixLength == 24 && !i.address.startsWith("127")) {
        m.localIP = i.address;
        localAddress = i.address;
        completer.complete(0);
        return;
      }
    }
    //
    for (hetima.HetiNetworkInterface i in l) {
      if (i.prefixLength == 64) {
        m.localIP = i.address;
        localAddress = i.address;
        completer.complete(0);
        return;
      }
    }
  }).catchError((e) {
    completer.completeError(e);
  });
  return completer.future;
}

