part of delphiniumapp;

/**
 * ui parts
 */
class FileListPanel {
  ui.VerticalPanel filelistForSubPanel = new ui.VerticalPanel();

  List<String> _fileList = [];

  async.StreamController<String> _controllerDelete = new async.StreamController.broadcast();

  async.Stream<String> get onDelete => _controllerDelete.stream;

  void clearFile() {
    _fileList.clear();
  }

  void addFile(String filename) {
    _fileList.add(filename);
  }

  void initFileListPanel() {
    filelistForSubPanel.clear();

    ui.FlexTable layout = new ui.FlexTable();
    layout.setCellSpacing(_fileList.length + 2);
    ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

    layout.setHtml(0, 0, "");
    cellFormatter.setColSpan(0, 0, 2);
    cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);

    layout.setWidget(1, 0, new ui.HtmlPanel("@"));
    layout.setWidget(1, 1, new ui.HtmlPanel("file"));
    for (int i = 0; i < _fileList.length; i++) {
      String fname = _fileList[i];
      event.ClickHandlerAdapter handler = new event.ClickHandlerAdapter((event.ClickEvent event) {
        _controllerDelete.add(fname);
        layout.setWidget(i + 2, 0, new ui.HtmlPanel("-"));
        _fileList.removeAt(i);
      });
      layout.setWidget(i + 2, 0, new ui.Button("x", handler));
      layout.setWidget(i + 2, 1, new ui.HtmlPanel("${_fileList[i]}"));
    }
    filelistForSubPanel.add(layout);
  }

}
