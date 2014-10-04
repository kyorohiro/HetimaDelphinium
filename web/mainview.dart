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

  ui.VerticalPanel _mainPanel = new ui.VerticalPanel();
  ui.VerticalPanel _subPanel = new ui.VerticalPanel();
  ui.FileUpload _fileUpload = new ui.FileUpload();

  async.StreamController _controllerTab = new async.StreamController.broadcast();

  async.Stream get onChangeTabState => _controllerTab.stream;
  async.Stream get onChangeMainButtonState => _mmainPanel.onChangeMainButtonState;
  async.Stream get onDeleteFileFromList => _minfoPanel.onDelete;
  async.Stream<FileSelectResult> get onSelectFile => _mmainPanel.onSelectFile;
  List<String> _fileList = [];

  MainPanel _mmainPanel = new MainPanel();
  FileListPanel _minfoPanel = new FileListPanel();

  void init() {
    initTab();
    _mmainPanel.initMainPanel();
    _minfoPanel.initInfoPanel();
  }

  void set localPort(String port) => _mmainPanel.setLocalPort(port);
  void set localIP(String ip) => _mmainPanel.setLocalIP(ip);
  void set globalPort(String port) => _mmainPanel.setGlobalPort(port);
  void set globalIP(String ip) => _mmainPanel.setGlobalIP(ip);

  void clearFile() {
    _minfoPanel.clearFile();
  }

  void addFile(String filename) {
    _minfoPanel.addFile(filename);
  }

  void initTab() {
    ui.TabBar bar = new ui.TabBar();
    bar.addTabText("main");
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
        _minfoPanel.initInfoPanel();
        _subPanel.add(_minfoPanel.filelistForSubPanel);
        _controllerTab.add(FILELIST);
      }
    }));

  }
}

class FileSelectResult
{
  String apath;
  String fname;
  hetima.HetimaFile file;
}