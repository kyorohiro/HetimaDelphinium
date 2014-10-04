part of delphiniumapp;

/**
 * app parts
 */
class HttpServer {
  String localIP = "0.0.0.0";
  int basePort = 18085;
  int _localPort = 18085;
  int get localPort => _localPort;

  Map<String, FileSelectResult> publicFileList = {};
  hetima.HetiHttpServer _server = null;

  async.StreamController<String> _controllerUpdateLocalServer = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateLocalServer => _controllerUpdateLocalServer.stream;

  async.Future<hetima.HetiHttpServer> _retryBind() {
    async.Completer<hetima.HetiHttpServer> completer = new async.Completer();
    int portMax = _localPort + 100;
    bindFunc() {
      hetima.HetiHttpServer.bind(new hetimacl.HetiSocketBuilderChrome(), localIP, _localPort).then((hetima.HetiHttpServer server) {
        completer.complete(server);
      }).catchError((e) {
        _localPort++;
        if (_localPort < portMax) {
          bindFunc();
        } else {
          completer.completeError(e);
        }
      });
    }
    bindFunc();
    return completer.future;
  }

  void stopServer() {
    if (_server == null) {
      return;
    }
    _server.close();
    _server = null;
  }

  async.Future<int> startServer() {
    print("startServer");
    _localPort = basePort;
    async.Completer<int> completer = new async.Completer();
    if (_server != null) {
      completer.completeError({});
      return completer.future;
    }

    _retryBind().then((hetima.HetiHttpServer server) {
      _controllerUpdateLocalServer.add("${_localPort}");
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
          for (String r in publicFileList.keys) {
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
          }).catchError((e) {
            req.socket.close();
          });
        }

        String path = req.info.line.requestTarget.substring(1);
        if (!publicFileList.containsKey(path)) {
          req.socket.close();
        } else {
          startResponse(req.socket, publicFileList[path]);
        }
      });
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  void startResponse(hetima.HetiSocket socket, FileSelectResult f) {
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

}
