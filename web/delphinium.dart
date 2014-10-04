import 'dart:html' as html;

import 'package:chrome/chrome_app.dart' as chromeapp;
import 'mainview.dart' as mainview;
import 'package:hetima/hetima.dart' as hetima;
import 'package:hetima/hetima_cl.dart' as hetimacl;
import 'dart:convert' as convert;
import 'package:hetima/hetima.dart' as hetima;
import 'dart:async' as async;
String address = "0.0.0.0";
String localAddress = "0.0.0.0";
int basePort = 18085;
int localPort = basePort;
int externalPort = basePort;

mainview.MainView m = new mainview.MainView();
hetima.HetiHttpServer server = null;
Map<String, mainview.FileSelectResult> fileList = {};

void main() {
  m.init();
  m.onChangeMainButtonState.listen((bool isDown) {
    if (isDown) {
      startServer().then((int v) {
        return startLocalIp();
      }).then((int v) {
        startPortMap();
      });
    } else {
      stopServer();
      stopPortMap();
    }
  });
  int id = 0;
  m.onSelectFile.listen((mainview.FileSelectResult result) {
    String label = "${id++}_${result.fname}";
    fileList[label] = result;
    m.addFile(label);
  });

  m.onDeleteFileFromList.listen((String fname) {
    fileList.remove(fname);
  });
}
hetima.HetiHttpServer _server = null;

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
        pppDevice.requestAddPortMapping(externalPort, hetima.UPnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP, localPort, localAddress, hetima.UPnpPPPDevice.VALUE_ENABLE, "HetimaDelphinium", 0).then((hetima.UPnpAddPortMappingResponse res) {
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

void stopPortMap() {
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

      pppDevice.requestDeletePortMapping(externalPort, hetima.UPnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP);
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

async.Future<hetima.HetiHttpServer> _retryBind() {
  async.Completer<hetima.HetiHttpServer> co = new async.Completer();
  int portMax = localPort + 100;
  a() {
    hetima.HetiHttpServer.bind(new hetimacl.HetiSocketBuilderChrome(), address, localPort).then((hetima.HetiHttpServer server) {
      co.complete(server);
    }).catchError((e) {
      localPort++;
      if (localPort < portMax) {
        a();
      } else {
        co.completeError(e);
      }
    });
  }
  a();
  return co.future;
}

async.Future<int> startServer() {
  print("startServer");
  localPort = basePort;
  externalPort = basePort;
  async.Completer<int> completer = new async.Completer();
  if (_server != null) {
    completer.completeError({});
    return completer.future;
  }

  _retryBind().then((hetima.HetiHttpServer server) {
    m.localPort = "${localPort}";
    _server = server;
    completer.complete(0);
    server.onNewRequest().listen((hetima.HetiHttpServerRequest req) {
      print("${req.info.line.requestTarget}");
      if (req.info.line.requestTarget.length < 0) {
        req.socket.close();
        return {};
      }
      if ("/index.html" == req.info.line.requestTarget) {

        StringBuffer content = new StringBuffer();
        content.write("<html>");
        content.write("<body>");
        for (String r in fileList.keys) {
          content.write("<div><a href=./${r}>${r}</div>");
        }
        content.write("</body>");
        content.write("</html>");

        String cv = content.toString();
        List<int> b = convert.UTF8.encode(content.toString());
        StringBuffer response = new StringBuffer();
        response.write("HTTP/1.1 200 OK'\r\n");
        response.write("Connection: close\r\n");
        response.write("Content-Length: ${b.length}\r\n");
        response.write("Content-Type: text/html\r\n");
        response.write("\r\n");
        return req.socket.send(convert.UTF8.encode(response.toString())).then((hetima.HetiSendInfo i) {
          return req.socket.send(b);
        }).then((hetima.HetiSendInfo i) {
          req.socket.close();
        }).catchError((e){
          req.socket.close();          
        });
      }

      String path = req.info.line.requestTarget.substring(1);
      if (!fileList.containsKey(path)) {
        req.socket.close();
      } else {
        startResponse(req.socket, fileList[path]);
      }
    });
  }).catchError((e) {
    completer.completeError(e);
  });
  return completer.future;
}

void startResponse(hetima.HetiSocket socket, mainview.FileSelectResult f) {
  hetima.ArrayBuilder response = new hetima.ArrayBuilder();
  int index = 0;
  int size = 1024;
  int length = 0;
  res() {
    int l = index + 1024;
    if (l < length) {
      l = length;
    }
    f.file.read(index, l).then((hetima.ReadResult r) {
      return socket.send(r.buffer);
    }).then((hetima.HetiSendInfo i) {
      if (l >= length) {
        socket.close();
      } else {
        index = l;
        res();
      }
    }).catchError((e) {
      socket.close();
    });
  }
  f.file.getLength().then((int l) {
    length = l;
    response.appendString("HTTP/1.1 200 OK'\r\n");
    response.appendString("Connection: close\r\n");
    response.appendString("Content-Length: ${length}\r\n");
    response.appendString("\r\n");
    socket.send(response.toList());
    f.file.read(0, length).then((hetima.ReadResult r) {
      return socket.send(r.buffer);
    }).then((hetima.HetiSendInfo i) {
      socket.close();
    }).catchError((e) {
      socket.close();
    });
  });
}

void stopServer() {
  if (_server == null) {
    return;
  }
  _server.close();
  _server = null;
}
