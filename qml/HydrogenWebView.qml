import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import io.thp.pyotherside 1.5

WebViewFlickable {
    id: webviewFlickable
    property string urlFromParent
    function runJavaScript(script) {
        webview.runJavaScript(script)
    }
    function enterSettingsView() {
        var settingsURL = app.getSessionURL(webview.url) + '/settings'
        webview.url = settingsURL
    }

    Private.VirtualKeyboardObserver {
        id: virtualKeyboardObserver
        active: webview.enabled

        // Update content height only after virtual keyboard fully opened.
        states: State {
            name: "boundHeightControl"
            when: virtualKeyboardObserver.opened && webview.enabled
            PropertyChanges {
                target: webview
                viewportHeight: isLandscape ? Screen.height - virtualKeyboardObserver.imSize
                                            : Screen.width - Qt.inputMethod.keyboardRectangle.width
            }
        }
    }
    Component.onCompleted: {
        startWebEngine()
    }

    webView {
        id: webview
        anchors.fill: parent
        onViewInitialized: {
            console.log("loading framescript")
            webview.loadFrameScript(Qt.resolvedUrl("framescript.js"))
            webview.addMessageListener("webview:log")
            webview.addMessageListener("webview:notificationCount")
        }
        onUrlChanged: {
            app.handleUrlChange(webview.url, app.openingArgument)
        }
        onRecvAsyncMessage: {
            switch (message) {
            case "webview:log":
                console.log("webapp-log: " + JSON.stringify(data))
                break
            case "webview:notificationCount":
                app.coverTitle = qsTr("Messages: %1").arg(data.count)
                app.coverMessages = data.top5
                break
            case "embed:linkclicked":
                var url = '/^http:\/\/localhost/'
                if (!data.uri.match('http://localhost'))
                    Qt.openUrlExternally(data['uri'])
                break
            default:
                console.log("Message: " + JSON.stringify(
                                message) + " data: " + JSON.stringify(data))
            }
        }
        onLoadedChanged: {
            if (webview.loaded) {
                var readFile = function(path) {
                    var file = new XMLHttpRequest();
                    file.open("GET", path, false); // Synchronous
                    file.send(null);
                    return file.responseText;
                }
                var notificationScript = readFile(Qt.resolvedUrl("notificationCount.js"));
                webview.runJavaScript(notificationScript);
            }
        }
    }
    function startWebEngine() {
        // NOTE: Settings are set and saved in prefs.js.
        //
        // If you need to disable one of the following settings, you must set
        // it to default explicitly, not just comment it out.

        // disable CORS
        WebEngineSettings.setPreference(
            "security.fileuri.strict_origin_policy", false,
            WebEngineSettings.BoolPref)

        /*** User Settings ***/
        // Zoom/scale
        WebEngineSettings.pixelRatio        = (wvConfig.zoom*Theme.pixelRatio*10)/10.0
        // Follow Ambience
        if (wvConfig.ambienceMode) {
            WebEngineSettings.colorScheme   = wvConfig.ambienceMode
        }
        // Memory Cache
        const wantCache = (wvConfig.memCache == 11) // automatic -> -1
            ? -1 // automatic
            : Math.round(wvConfig.memCache * 12.8 * 1024) // slider display shows value * 12.8 in MB, we want KB
        console.debug("Setting Mozilla memory cache to", wantCache)
        WebEngineSettings.setPreference(
            "browser.cache.memory.capacity", wantCache,
            WebEngineSettings.IntPref);
    }
}

