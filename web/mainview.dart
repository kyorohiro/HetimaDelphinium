import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/text.dart' as text;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;
import 'package:dart_web_toolkit/validation.dart' as validation;

import 'dart:async' as async;

class MainView {
  static const int MAIN = 0;
  static const int INFO = 1;

  ui.VerticalPanel _mainPanel = new ui.VerticalPanel();
  ui.VerticalPanel _subPanel = new ui.VerticalPanel();
  ui.VerticalPanel _mainForSubPanel = new ui.VerticalPanel();
  ui.VerticalPanel _otherForSubPanel = new ui.VerticalPanel();

  async.StreamController _controllerTab = new async.StreamController.broadcast();
  async.StreamController<bool> _controllerMainButton = new async.StreamController.broadcast();

  async.Stream get onChangeTabState => _controllerTab.stream;
  async.Stream get onChangeMainButtonState => _controllerMainButton.stream;

  void init() {
    initTab();
    initMainPanel();
  }

  void initMainPanel() {
    {
      ui.VerticalPanel vpanel = new ui.VerticalPanel();

      ui.HorizontalPanel togglePanel = new ui.HorizontalPanel();
      togglePanel.spacing = 1;

      vpanel.add(togglePanel);

      ui.ToggleButton normalToggleButton = null;
      normalToggleButton = new ui.ToggleButton.fromImage(new ui.Image("start.png"), downImage: new ui.Image("stop.png"), handler: new event.ClickHandlerAdapter((event.ClickEvent event) {
        print("click${normalToggleButton.isDown()}");
        _controllerMainButton.add(normalToggleButton.isDown());
      }));
      togglePanel.add(normalToggleButton);

      _mainForSubPanel.add(vpanel);
    }
    {
      ui.FlexTable layout = new ui.FlexTable();
      layout.setCellSpacing(9);
      ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

      layout.setHtml(0, 0, "");
      cellFormatter.setColSpan(0, 0, 2);
      cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);
      layout.setWidget(1, 0, new ui.HtmlPanel("IP"));
      layout.setWidget(1, 1, new ui.HtmlPanel("[]"));
      layout.setWidget(2, 0, new ui.HtmlPanel("Port"));
      layout.setWidget(2, 1, new ui.HtmlPanel("[]"));
      layout.setWidget(3, 0, new ui.HtmlPanel("Local IP"));
      layout.setWidget(3, 1, new ui.HtmlPanel("[]"));
      layout.setWidget(4, 0, new ui.HtmlPanel("Local Port"));
      layout.setWidget(4, 1, new ui.HtmlPanel("[]"));
//      ui.RootPanel.get().add(layout);
      _mainForSubPanel.add(layout);
    }
  }

  void initTab() {
    ui.TabBar bar = new ui.TabBar();
    bar.addTabText("main");
    bar.addTabText("info");
    bar.selectTab(0);
    _mainPanel.add(bar);
    _mainPanel.add(_subPanel);
    _subPanel.clear();
    _subPanel.add(_mainForSubPanel);
    
//    ui.RootPanel.get().add(bar);
    ui.RootPanel.get().add(_mainPanel);

    bar.addSelectionHandler(new event.SelectionHandlerAdapter((event.SelectionEvent evt) {
      int selectedTabIndx = evt.getSelectedItem();
      if (selectedTabIndx == 0) {
        _subPanel.clear();
        _subPanel.add(_mainForSubPanel);
        _controllerTab.add(MAIN);
      } else if (selectedTabIndx == 1) {
        _subPanel.clear();
        _subPanel.add(_otherForSubPanel);
        _controllerTab.add(INFO);
      }
    }));

  }
}
