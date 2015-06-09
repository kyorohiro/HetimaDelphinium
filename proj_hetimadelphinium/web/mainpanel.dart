part of delphiniumapp;

/**
 * ui parts
 */
class MainPanel {
  ui.VerticalPanel mainForSubPanel = new ui.VerticalPanel();
  ui.FileUpload _fileUpload = new ui.FileUpload();

  async.StreamController _controllerTab = new async.StreamController.broadcast();
  async.StreamController<bool> _controllerMainButton = new async.StreamController.broadcast();
  async.StreamController<FileSelectResult> _controllerFileSelect = new async.StreamController.broadcast();

  async.Stream get onChangeMainButtonState => _controllerMainButton.stream;
  async.Stream<FileSelectResult> get onSelectFile => _controllerFileSelect.stream;
  List<String> _fileList = [];

  ui.Html _localPort = new ui.Html("[]");
  ui.Html _localIP = new ui.Html("[]");
  ui.Html _globalPort = new ui.Html("[]");
  ui.Html _globalIP = new ui.Html("[]");
  String _downloadPath = "hetima";

  ui.Html _globalAccessPoint = new ui.Html("[]");
  ui.Html _localAccessPoint = new ui.Html("[]");

  void setDownloadPath(String path) {
    _downloadPath = path;
    _globalAccessPoint.text = "http://${_globalIP.text}:${_globalPort.text}/${_downloadPath}/";
    _localAccessPoint.text = "http://${_localIP.text}:${_localPort.text}/${_downloadPath}/";
  }

  void updateAccessPointer() {
    _globalAccessPoint.text = "http://${_globalIP.text}:${_globalPort.text}/${_downloadPath}/";
    _localAccessPoint.text = "http://${_localIP.text}:${_localPort.text}/${_downloadPath}/";
  }
  void setLocalPort(String port) {
    _localPort.text = port;
    updateAccessPointer();
  }

  void setLocalIP(String ip) {
    _localIP.text = ip;
    updateAccessPointer();
  }

  void setGlobalPort(String port) {
    _globalPort.text = port;
    updateAccessPointer();
  }

  void setGlobalIP(String ip) {
    _globalIP.text = ip;
    updateAccessPointer();
  }

  void clearFile() {
    _fileList.clear();
  }

  void addFile(String filename) {
    _fileList.add(filename);
  }

  void initMainPanel() {
    {
      mainForSubPanel.add(_fileUpload);
      event.ChangeHandler handler = new event.ChangeHandlerAdapter((event.ChangeEvent e) {
        print("##${_fileUpload.name}");
        print("##${_fileUpload.getFilename()}");
        print("##${_fileUpload.title}");
        String path = _fileUpload.getFilename();
        for (html.File f in (_fileUpload.getElement() as html.InputElement).files) {
          hetima.HetimaDataBlob file = new hetima.HetimaDataBlob(f);
          file.getLength().then((int length) {
            print("###${length}");
            FileSelectResult ff = new FileSelectResult();
            ff.file = file;
            ff.fname = f.name;
            ff.apath = path;
            _controllerFileSelect.add(ff);
          });
        }
      });
      _fileUpload.addChangeHandler(handler);
      _fileUpload.addStyleName("hetima-grid");
      _fileUpload.setHeight("1.5cm");
    }
    {
      ui.VerticalPanel vpanel = new ui.VerticalPanel();

      ui.HorizontalPanel togglePanel = new ui.HorizontalPanel();
      togglePanel.spacing = 1;

      vpanel.add(togglePanel);

      ui.Button normalToggleButton = null;
      bool isDown = false;
      normalToggleButton = new ui.Button("start", new event.ClickHandlerAdapter((event.ClickEvent event) {
        print("click${isDown}");
        if (isDown) {
          isDown = false;
          normalToggleButton.text = "start";
        } else {
          isDown = true;
          normalToggleButton.text = "stop";
        }
        _controllerMainButton.add(isDown);
      }));
      normalToggleButton.addStyleName("hetima-grid");
      togglePanel.add(normalToggleButton);
      togglePanel.addStyleName("hetima-grid");
      mainForSubPanel.add(vpanel);
    }
    {
      ui.FlexTable layout = new ui.FlexTable();
      layout.setCellSpacing(9);
      ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

      layout.setHtml(0, 0, "");
      cellFormatter.setColSpan(0, 0, 2);
      cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);
      layout.setWidget(1, 0, new ui.HtmlPanel("IP"));

      layout.setWidget(1, 1, _globalIP);
      layout.setWidget(2, 0, new ui.HtmlPanel("Port"));
      layout.setWidget(2, 1, _globalPort);
      layout.setWidget(3, 0, new ui.HtmlPanel("Local IP"));
      layout.setWidget(3, 1, _localIP);
      layout.setWidget(4, 0, new ui.HtmlPanel("Local Port"));
      layout.setWidget(4, 1, _localPort);
      mainForSubPanel.add(layout);
    }
    {
      ui.FlexTable layout = new ui.FlexTable();
      layout.setCellSpacing(9);
      ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

      layout.setHtml(0, 0, "");
      cellFormatter.setColSpan(0, 0, 2);
      cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);
      layout.setWidget(1, 0, new ui.HtmlPanel("@"));
      layout.setWidget(1, 1, new ui.HtmlPanel("Access Point"));

      layout.setWidget(2, 1, _globalAccessPoint);
      layout.setWidget(3, 1, _localAccessPoint);
      mainForSubPanel.add(layout);
    }

  }

}
