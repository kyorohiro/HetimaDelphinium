
chrome.app.runtime.onLaunched.addListener(function(launchData) {
  chrome.app.window.create('delphinium.html', {
    'id': '_mainWindow', 'bounds': {'width': 300, 'height': 300 }
  });
});
