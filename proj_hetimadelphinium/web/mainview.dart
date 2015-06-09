part of delphiniumapp;

/**
 * ui parts
 * MainView
 *  |_MainPanel
 *  |_FileListPanel
 */
class MainView {
  static const int MAIN = 0;
  static const int FILELIST = 1;
  static const int INFO = 2;

  ui.VerticalPanel _mainPanel = new ui.VerticalPanel();
  ui.VerticalPanel _subPanel = new ui.VerticalPanel();
  ui.FileUpload _fileUpload = new ui.FileUpload();

  MainPanel _mmainPanel = new MainPanel();
  FileListPanel _mfileListPanel = new FileListPanel();
  InfoPanel _minfoPane = new InfoPanel();
  void set downloadPath(String path) {
    _mmainPanel.setDownloadPath(path);
    _minfoPane.setDownloadPath(path);
  }

  async.StreamController _controllerTab = new async.StreamController.broadcast();

  async.Stream get onChangeTabState => _controllerTab.stream;
  async.Stream get onChangeMainButtonState => _mmainPanel.onChangeMainButtonState;
  async.Stream get onDeleteFileFromList => _mfileListPanel.onDelete;

  async.Stream<String> get onChRootPath => _minfoPane.onChRootPath;

  async.Stream<String> get onInitAddress => _minfoPane.onInitAddress;

  async.Stream<FileSelectResult> get onSelectFile => _mmainPanel.onSelectFile;
  List<String> _fileList = [];


  void init() {
    initTab();
    _mmainPanel.initMainPanel();
    _mfileListPanel.initFileListPanel();
    _minfoPane.initInfoPanel();
  }

  void set localPort(String port) => _mmainPanel.setLocalPort(port);
  void set localIP(String ip) => _mmainPanel.setLocalIP(ip);
  void set globalPort(String port) => _mmainPanel.setGlobalPort(port);
  void set globalIP(String ip) => _mmainPanel.setGlobalIP(ip);

  void clearFile() {
    _mfileListPanel.clearFile();
  }

  void addFile(String filename) {
    _mfileListPanel.addFile(filename);
  }

  void initTab() {
    ui.TabBar bar = new ui.TabBar();
    bar.addTabText("main");
    bar.addTabText("files");
    bar.addTabText("info");
    bar.selectTab(0);
    _mainPanel.add(bar);
    _mainPanel.add(_subPanel);
    _subPanel.clear();
    _subPanel.add(_mmainPanel.mainForSubPanel);

    ui.RootPanel.get().add(_mainPanel);

    bar.addSelectionHandler(new event.SelectionHandlerAdapter((event.SelectionEvent evt) {
      int selectedTabIndx = evt.getSelectedItem();
      if (selectedTabIndx == 0) {
        _subPanel.clear();
        _subPanel.add(_mmainPanel.mainForSubPanel);
        _controllerTab.add(MAIN);
      } else if (selectedTabIndx == 1) {
        _subPanel.clear();
        _mfileListPanel.initFileListPanel();
        _subPanel.add(_mfileListPanel.filelistForSubPanel);
        _controllerTab.add(FILELIST);
      } else if (selectedTabIndx == 2) {
        _subPanel.clear();
        _subPanel.add(_minfoPane.infoForSubPanel);
        _controllerTab.add(INFO);
      }
    }));

  }
}

class FileSelectResult {
  String apath;
  String fname;
  hetima.HetimaData file;
}
