// Copyright (c) 2022,2023 Peter G. (nephros)
// SPDX-License-Identifier: Apache-2.0

import QtQuick 2.6
import Sailfish.Silica 1.0

DockedPanel { id: root

    property int serverPort
    ListModel {id: mozlinks
        ListElement { title: 'moz:c'; mozurl: "about:cache" }
        ListElement { title: 'moz:m'; mozurl: "about:memory" }
        ListElement { title: 'moz:p'; mozurl: "about:performance" }
        ListElement { title: 'moz:n'; mozurl: "about:networking" }
        ListElement { title: 'moz:sw'; mozurl: "about:serviceworkers" }
        ListElement { title: 'moz:rtc'; mozurl: "about:webrtc" }
    }
    dock: Dock.Bottom
    modal: false

    animationDuration : 250
    height: content.height
    width: parent.width
    flickableDirection: Flickable.HorizontalFlick
    contentWidth: content.width
    Row { id: content
        anchors.verticalCenter: parent.verticalCenter
        height: firstButton.height + Theme.paddingMedium
        spacing: Theme.paddingSmall
        IconButton{ id: firstButton
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "image://theme/icon-m-back"
            enabled: webviewPage.hydrogenwebview.webView.canGoBack
            onClicked: webviewPage.hydrogenwebview.webView.goBack()
        }
        Repeater {
            model: mozlinks
            delegate: Button {
                anchors.verticalCenter: parent.verticalCenter
                preferredWidth: Theme.buttonWidthTiny
                text: title
                onClicked: {
                    webviewPage.hydrogenwebview.webView.url=mozurl
                }
            }
        }
        IconButton{ id: lastButton
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "image://theme/icon-m-reload"
            enabled: !!serverPort
            onClicked: webviewPage.hydrogenwebview.webView.url= Qt.resolvedUrl("http://localhost:" + serverPort + "/index.html")
        }
    }

    Separator { anchors.verticalCenter: parent.top; anchors.horizontalCenter: parent.horizontalCenter; }
}

// vim: expandtab ts=4 st=4 sw=4 filetype=javascript
