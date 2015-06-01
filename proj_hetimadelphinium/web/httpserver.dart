part of delphiniumapp;


/**
 * app parts
 */
class DelphiniumHttpServer extends hetima.HetiHttpServerPlus {
  static const String SYSTEM_FILE_PATH = "hetima.system";
  String dataPath = "hetima";

  Map<String, FileSelectResult> _publicFileList = {};

  DelphiniumHttpServer() :super(new hetima.HetiSocketBuilderChrome()){
    _init();
    this.onResponse.listen(onHundleRequest);
  }

  _init() {
    {
      FileSelectResult result = new FileSelectResult();
      result.file = SwfPlayerBuffer.createPlayerswf();
      result.fname = "hetima.system.player.swf";
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

  void onHundleRequest(hetima.HetiHttpServerPlusResponseItem item) {
    hetima.HetiHttpServerRequest req = item.req;
    print("${req.info.line.requestTarget}");
    if (req.info.line.requestTarget.length < 0) {
      req.socket.close();
      return;
    }
    if ("/${dataPath}/index.html" == req.info.line.requestTarget || "/${dataPath}/" == req.info.line.requestTarget) {
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

    response(req,  _publicFileList[filename].file, contentType(filename));
  }

  async.Future _startResponseHomePage(hetima.HetiSocket socket) {
    StringBuffer content = new StringBuffer();
    content.write("<html>");
    content.write("<body>");
    for (String r in _publicFileList.keys) {
      if(_publicFileList[r].apath == DelphiniumHttpServer.SYSTEM_FILE_PATH) {
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


}
