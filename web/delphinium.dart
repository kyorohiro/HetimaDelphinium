import 'dart:html' as html;

import 'package:chrome/chrome_app.dart' as chromeapp;
import 'mainview.dart' as mainview;
import 'package:hetima/hetima.dart' as hetima;
import 'package:hetima/hetima_cl.dart' as hetimacl;
import 'dart:convert' as convert;
import 'package:hetima/hetima.dart' as hetima;
import 'dart:async' as async;
String address = "0.0.0.0";
int port = 18085;

mainview.MainView m = new mainview.MainView();
hetima.HetiHttpServer server = null;
Map<String, mainview.FileSelectResult> fileList = {};

void main() {
  m.init();
  m.onChangeMainButtonState.listen((bool isDown) {
    if (isDown) {
      startServer().then((int v){
        return startLocalIp();
      }).then((int v) {
        
      });
    } else {
      stopServer();
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

async.Future<int> startLocalIp() {
  async.Completer<int> completer = new async.Completer();
  (new hetimacl.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> l) {
    // search 24
    for(hetima.HetiNetworkInterface i in l) {
      if(i.prefixLength == 24 && !i.address.startsWith("127")) {
        m.localIP = i.address;
        completer.complete(0);
        return;
      }
    }
    //
    for(hetima.HetiNetworkInterface i in l) {
      if(i.prefixLength == 64) {
        m.localIP = i.address;
        completer.complete(0);
        return;
      }
    }
  }).catchError((e){
    completer.completeError(e);
  });
  return completer.future;
}

async.Future<hetima.HetiHttpServer> _retryBind() {
  async.Completer<hetima.HetiHttpServer> co = new async.Completer();
  int portMax = port + 100;
  a() {
    hetima.HetiHttpServer.bind(new hetimacl.HetiSocketBuilderChrome(), address, port).then((hetima.HetiHttpServer server) {
      co.complete(server);
    }).catchError((e) {
      port++;
      if (port < portMax) {
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
  async.Completer<int> completer = new async.Completer();
  if (_server != null) {
    completer.completeError({});
    return completer.future;
  }

  _retryBind().then((hetima.HetiHttpServer server) {
    m.localPort = "${port}";
    _server = server;
    completer.complete(0);
    server.onNewRequest().listen((hetima.HetiHttpServerRequest req) {
      print("${req.info.line.requestTarget}");
      if (req.info.line.requestTarget.length < 0) {
        req.socket.close();
        return {};
      }
      if ("/index.html" == req.info.line.requestTarget) {
        StringBuffer buffer = new StringBuffer();
        for (String r in fileList.keys) {
          buffer.write("<div><a href=./${r}>${r}</div>");
        }
        return req.socket.send(convert.UTF8.encode(buffer.toString())).then((hetima.HetiSendInfo i) {
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
  }).catchError((e){
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
