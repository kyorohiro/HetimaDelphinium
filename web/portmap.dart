part of delphiniumapp;

class PortMap {
  String localAddress = "0.0.0.0";
  int localPort = 18085;
  int externalPort = 18085;

  async.StreamController<String> _controllerUpdateGlobalPort = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateGlobalPort => _controllerUpdateGlobalPort.stream;

  async.StreamController<String> _controllerUpdateGlobalIp = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateGlobalIp => _controllerUpdateGlobalIp.stream;


  async.StreamController<String> _controllerUpdateLocalIp = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateLocalIp => _controllerUpdateLocalIp.stream;

  void startPortMap() {
    hetima.UpnpDeviceSearcher.createInstance(new hetimacl.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
      searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          return;
        }
        hetima.UPnpDeviceInfo info = searcher.deviceInfoList.first;
        hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
        pppDevice.requestGetExternalIPAddress().then((hetima.UPnpGetExternalIPAddressResponse res) {
          res.externalIp;
          _controllerUpdateGlobalIp.add(res.externalIp);
        });
        int baseExternalPort = externalPort + 50;
        a() {
          pppDevice.requestAddPortMapping(externalPort, hetima.UPnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP, localPort, localAddress, hetima.UPnpPPPDevice.VALUE_ENABLE, "HetimaDelphinium", 0).then((hetima.UPnpAddPortMappingResponse res) {
            if (200 == res.resultCode) {
              _controllerUpdateGlobalPort.add("${externalPort}");              
              return;
            }
            if (-500 == res.resultCode) {
              externalPort++;
              if (externalPort < baseExternalPort) {
                a();
              }
            }
          });
        }
        ;
        a();
      });
    });
  }

  void deleteAllPortMap() {
    hetima.UpnpDeviceSearcher.createInstance(new hetimacl.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
      searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          return;
        }
        int index = 0;
        List<int> portList = [];
        b(hetima.UPnpPPPDevice pppDevice) {
          for (int port in portList) {
            pppDevice.requestDeletePortMapping(port, hetima.UPnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP);
          }
        }
        a() {
          hetima.UPnpDeviceInfo info = searcher.deviceInfoList.first;
          hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
          pppDevice.requestGetGenericPortMapping(index++).then((hetima.UPnpGetGenericPortMappingResponse res) {
            if (res.resultCode != 200) {
              b(pppDevice);
              return;
            }
            String description = res.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
            String port = res.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
            String ip = res.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
            if (description == "HetimaDelphinium") {
              int portAsNum = int.parse(port);
              portList.add(portAsNum);
            }
            if (port.replaceAll(" |\t|\r|\n", "") == "" && ip.replaceAll(" |\t|\r|\n", "") == "") {
              b(pppDevice);
              return;
            }
            a();
          });
        }
        a();
      });
    });
  }

  async.Future<int> startLocalIp() {
    async.Completer<int> completer = new async.Completer();
    (new hetimacl.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> l) {
      // search 24
      for (hetima.HetiNetworkInterface i in l) {
        if (i.prefixLength == 24 && !i.address.startsWith("127")) {
          _controllerUpdateLocalIp.add(i.address);
          localAddress = i.address;
          completer.complete(0);
          return;
        }
      }
      //
      for (hetima.HetiNetworkInterface i in l) {
        if (i.prefixLength == 64) {
          _controllerUpdateLocalIp.add(i.address);
          localAddress = i.address;
          completer.complete(0);
          return;
        }
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }
}
