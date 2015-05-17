part of delphiniumapp;

/**
 * ui parts
 */
class InfoPanel {
  ui.VerticalPanel infoForSubPanel = new ui.VerticalPanel();
  ui.TextBox _rootPath = new ui.TextBox();
  ui.TextBox _initialAddress = new ui.TextBox();

  String get rootPath => _rootPath.text;
  String get initAddress => _initialAddress.text;

  async.StreamController<String> _controllerRootPath = new async.StreamController.broadcast();
  async.Stream<String> get onChRootPath => _controllerRootPath.stream;

  async.StreamController<String> _controllerInitAddress = new async.StreamController.broadcast();
  async.Stream<String> get onInitAddress => _controllerInitAddress.stream;

  InfoPanel() {
    _initialAddress.text = "0.0.0.0";
    _rootPath.text = "hetima";
  }

  void setDownloadPath(String path) {
    _rootPath.text = path;
  }

  void initInfoPanel() {
    infoForSubPanel.clear();

    ui.FlexTable layout = new ui.FlexTable();
    layout.setCellSpacing(5);
    ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

    layout.setHtml(0, 0, "");
    cellFormatter.setColSpan(0, 0, 2);
    cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);

    layout.setWidget(1, 0, new ui.HtmlPanel("root path"));
    layout.setWidget(2, 1, _rootPath);
    layout.setWidget(3, 0, new ui.HtmlPanel("initial ip"));
    layout.setWidget(4, 1, _initialAddress);
//    _rootPath
    infoForSubPanel.add(layout);
  }

}
