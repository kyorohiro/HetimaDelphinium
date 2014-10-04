library a;
import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/text.dart' as text;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;
import 'package:dart_web_toolkit/validation.dart' as validation;
import 'dart:html' as html;
import 'dart:async' as async;
import 'package:hetima/hetima.dart' as hetima;
import 'package:hetima/hetima_cl.dart' as hetimacl;
part 'mainpanel.dart';
part 'infopanel.dart';

class MainView {
  static const int MAIN = 0;
  static const int INFO = 1;

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
  InfoPanel _minfoPanel = new InfoPanel();

  void init() {
    initTab();
    _mmainPanel.initMainPanel();
    _minfoPanel.initInfoPanel();
  }

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
        _subPanel.add(_minfoPanel.otherForSubPanel);
        _controllerTab.add(INFO);
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