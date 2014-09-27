
import 'dart:html';

import 'package:chrome/chrome_app.dart' as chrome;
import 'mainview.dart' as mainview;
import 'package:hetima/hetima.dart' as hetima;
import 'package:hetima/hetima_cl.dart' as hetimacl;
import 'dart:convert' as convert;
String address = "0.0.0.0";
int port = 18085;

mainview.MainView m = new mainview.MainView();
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
hetima.HetiServerSocket _server = null;
void startServer() {
  print("startServer");
   (new hetimacl.HetiSocketBuilderChrome()).startServer(address, port).then((hetima.HetiServerSocket server) {
     _server = server;
     _server.onAccept().listen((hetima.HetiSocket s) {
       print("accept");
       s.onReceive().listen((hetima.HetiReceiveInfo info){
         print("receive");
         s.send(convert.UTF8.encode("hello")).then((hetima.HetiSendInfo info) {
           s.close();
         });
       });
     });
   }).catchError((e){
     print("error");
   });
}

void stopServer() {
  
}
