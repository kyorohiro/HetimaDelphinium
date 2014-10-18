part of delphiniumapp;

/**
 * app parts
 */
class HttpServer {
  static const String SYSTEM_FILE_PATH = "hetima.system";
  String localIP = "0.0.0.0";
  int basePort = 18085;
  int _localPort = 18085;
  int get localPort => _localPort;
  String dataPath = "hetima";

  Map<String, FileSelectResult> _publicFileList = {};
  hetima.HetiHttpServer _server = null;

  async.StreamController<String> _controllerUpdateLocalServer = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateLocalServer => _controllerUpdateLocalServer.stream;

  HttpServer() {
    _init();
  }

  _init() {
    {
      FileSelectResult result = new FileSelectResult();
      result.file = SwfPlayerBuffer.createPlayerswf();
      result.fname = "hetima.system.player.swf";
      result.apath = "hetima.system";
      addFile(result.fname, result);
    }
    {
      FileSelectResult result = new FileSelectResult();
      result.file = SwfPlayerBuffer.createSwfObject();
      result.fname = "hetima.system.swfobject.js";
      result.apath = "hetima.system";
      addFile(result.fname, result);
    }
  }

  void addFile(String name, FileSelectResult fileinfo) {
    String key = hetima.PercentEncode.encode(convert.UTF8.encode(name));
    _publicFileList[key] = fileinfo;
  }

  void removeFile(String name) {
    String key = hetima.PercentEncode.encode(convert.UTF8.encode(name));
    _publicFileList.remove(key);
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
      server.onNewRequest().listen(_hundleRequest);
    }).catchError((e) {
      completer.completeError(e);
    });

    return completer.future;
  }

  void _hundleRequest(hetima.HetiHttpServerRequest req) {
    print("${req.info.line.requestTarget}");
    if (req.info.line.requestTarget.length < 0) {
      req.socket.close();
      return;
    }
    if ("/${dataPath}/index.html" == req.info.line.requestTarget || "/${dataPath}/" == req.info.line.requestTarget || "/${dataPath}" == req.info.line.requestTarget) {
      _startResponseHomePage(req.socket);
      return;
    }

    String path = req.info.line.requestTarget.substring("/${dataPath}/".length);
    int index = path.indexOf("?");
    if (index == -1) {
      index = path.length;
    }
    String filename = path.substring(0, index);
    String request = path.substring(index);

    if (!_publicFileList.containsKey(filename)) {
      req.socket.close();
      return;
    }

    if ("?preview=true" == request) {
      _startResponsePreviewPage(req.socket, filename);
      return;
    }

    hetima.HetiHttpResponseHeaderField header = req.info.find(hetima.RfcTable.HEADER_FIELD_RANGE);
    if (header != null) {
      typed_data.Uint8List buff = new typed_data.Uint8List.fromList(convert.UTF8.encode(header.fieldValue));
      hetima.ArrayBuilder builder = new hetima.ArrayBuilder.fromList(buff);
      builder.fin();
      hetima.HetiHttpResponse.decodeRequestRangeValue(new hetima.EasyParser(builder)).then((hetima.HetiHttpRequestRange range) {
        _startResponseRangeFile(req.socket, _publicFileList[filename].file, contentType(filename), range.start, range.end);
      });
    } else {
      _startResponseFile(req.socket, _publicFileList[filename].file);
    }
  }

  async.Future _startResponseHomePage(hetima.HetiSocket socket) {
    StringBuffer content = new StringBuffer();
    content.write("<html>");
    content.write("<body>");
    for (String r in _publicFileList.keys) {
      if(_publicFileList[r].apath == HttpServer.SYSTEM_FILE_PATH) {
        continue;
      }
      content.write("<div><a href=./${r}>${r}</a>");
      if (isVideoFile("${r}") || isAudioFile("${r}")) {
        content.write("<a href=./${r}?preview=true>(preview)</a></div>");
      } else {
        content.write("</div>");
      }
    }
    content.write("</body>");
    content.write("</html>");

    String cv = content.toString();
    List<int> b = convert.UTF8.encode(content.toString());
    StringBuffer response = new StringBuffer();
    response.write("HTTP/1.1 200 OK\r\n");
    response.write("Connection: close\r\n");
    response.write("Content-Length: ${b.length}\r\n");
    response.write("Content-Type: text/html\r\n");
    response.write("\r\n");
    return socket.send(convert.UTF8.encode(response.toString())).then((hetima.HetiSendInfo i) {
      return socket.send(b);
    }).then((hetima.HetiSendInfo i) {
      socket.close();
    }).catchError((e) {
      socket.close();
    });
  }

  async.Future _startResponsePreviewPage(hetima.HetiSocket socket, String path) {
    StringBuffer content = new StringBuffer();
    if (isFlvFile(path)) {
      content.write(SwfPlayerBuffer.previewFlvHtml(path));
    } else {
      content.write("<html>");
      content.write("<body>");
      if (isVideoFile(path)) {
        content.write("<video src=\"${path}\" controls autoplay><p>unsupport video tag</p></video>");
      } else if (isAudioFile(path)) {
        content.write("<audio src=\"${path}\" controls autoplay><p>unsupport video tag</p></audio>");
      }
      content.write("</body>");
      content.write("</html>");
    }

    String cv = content.toString();
    List<int> b = convert.UTF8.encode(content.toString());
    StringBuffer response = new StringBuffer();
    response.write("HTTP/1.1 200 OK\r\n");
    response.write("Connection: close\r\n");
    response.write("Content-Length: ${b.length}\r\n");
    response.write("Content-Type: text/html\r\n");
    response.write("\r\n");
    return socket.send(convert.UTF8.encode(response.toString())).then((hetima.HetiSendInfo i) {
      return socket.send(b);
    }).then((hetima.HetiSendInfo i) {
      socket.close();
    }).catchError((e) {
      socket.close();
    });
  }

  void _startResponseRangeFile(hetima.HetiSocket socket, hetima.HetimaFile file, String contentType, int start, int end) {
    hetima.ArrayBuilder response = new hetima.ArrayBuilder();
    file.getLength().then((int length) {
      if (end == -1 || end > length - 1) {
        end = length - 1;
      }
      int contentLength = end - start + 1;
      response.appendString("HTTP/1.1 206 Partial Content\r\n");
      response.appendString("Connection: close\r\n");
      response.appendString("Content-Length: ${contentLength}\r\n");
      response.appendString("Content-Type: ${contentType}\r\n");
      response.appendString("Content-Range: bytes ${start}-${end}/${length}\r\n");
      response.appendString("\r\n");
      print(response.toText());
      socket.send(response.toList()).then((hetima.HetiSendInfo i) {
        _startResponseBuffer(socket, file, start, contentLength);
      }).catchError((e) {
        socket.close();
      });
    });
  }

  void _startResponseFile(hetima.HetiSocket socket, hetima.HetimaFile file) {
    hetima.ArrayBuilder response = new hetima.ArrayBuilder();
    file.getLength().then((int length) {
      response.appendString("HTTP/1.1 200 OK\r\n");
      response.appendString("Connection: close\r\n");
      response.appendString("Content-Length: ${length}\r\n");
      response.appendString("\r\n");
      socket.send(response.toList()).then((hetima.HetiSendInfo i) {
        _startResponseBuffer(socket, file, 0, length);
      }).catchError((e) {
        socket.close();
      });
    });
  }

  void _startResponseBuffer(hetima.HetiSocket socket, hetima.HetimaFile file, int index, int length) {
    int start = index;
    responseTask() {
      int end = start + 256 * 1024;
      if (end > (index + length)) {
        end = (index + length);
      }
      print("####### ${start} ${end}");
      file.read(start, end).then((hetima.ReadResult readResult) {
        return socket.send(readResult.buffer);
      }).then((hetima.HetiSendInfo i) {
        if (end >= (index + length)) {
          socket.close();
        } else {
          start = end;
          responseTask();
        }
      }).catchError((e) {
        socket.close();
      }).catchError((e) {

      });
    }
    responseTask();
  }

  bool isFlvFile(String path) {
    String type = contentType(path);
    if (type.startsWith("video/x-flv")) {
      return true;
    } else {
      return false;
    }
  }

  bool isVideoFile(String path) {
    String type = contentType(path);
    if (type.startsWith("video/")) {
      return true;
    } else {
      return false;
    }
  }

  //
  bool isAudioFile(String path) {
    String type = contentType(path);
    if (type.startsWith("audio/")) {
      return true;
    } else {
      return false;
    }
  }

  Map<String, String> contentTypeMap = {
    ".mp4": "video/mp4",
    ".ogv": "video/ogg",
    ".webm": "video/webm",
    ".m4v": "video/x-m4v",
    ".flv": "video/x-flv",
    ".wmv": "video/x-ms-wmv",
    ".ogg": "audio/ogg",
    ".oga": "audio/ogg",
    ".m4a": "audio/aac",
    ".mp3": "audio/mp3",
    ".midi": "audio/midi",
    ".mid": "audio/midi",
  };

  String contentType(String path) {
    int index = path.lastIndexOf(".");
    if (index <= 0) {
      return "application/octet-stream";
    }
    String suffix = path.substring(index);
    if (contentTypeMap.containsKey(suffix)) {
      return contentTypeMap[suffix];
    } else {
      return "application/octet-stream";
    }
  }

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

}
