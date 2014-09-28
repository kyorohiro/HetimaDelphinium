
import 'dart:html';

import 'package:chrome/chrome_app.dart' as chrome;
import 'mainview.dart' as mainview;
import 'package:hetima/hetima.dart' as hetima;
import 'package:hetima/hetima_cl.dart' as hetimacl;
import 'dart:convert' as convert;
String address = "0.0.0.0";
int port = 18085;

mainview.MainView m = new mainview.MainView();
hetima.HetiHttpServer server = null;

void main() {
  m.init();
  m.onChangeMainButtonState.listen((bool isDown){
    if(isDown) {
      startServer();
    } else {
      stopServer();
    }
  });
}
hetima.HetiHttpServer _server = null;

void startServer() {
  print("startServer");
  if(_server != null) {
    return;
  }
  hetima.HetiHttpServer.bind(new hetimacl.HetiSocketBuilderChrome(), address, port).then((hetima.HetiHttpServer server){
    _server = server;
    server.onNewRequest().listen((hetima.HetiHttpServerRequest req) {
      print("${req.info.line.requestTarget}");
      if("/index.html" == req.info.line.requestTarget) {
        return req.socket.send(convert.UTF8.encode("hello")).then((hetima.HetiSendInfo i) {
          req.socket.close();
        });
      } else {
        req.socket.close();
      }
    });
  });
}

void stopServer() {
  if(_server == null) {
    return;
  }
  _server.close();
  _server = null;
}
