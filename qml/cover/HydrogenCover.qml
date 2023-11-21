import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    readonly property color hyColor:               "#0dbd8b"
    readonly property color hylightColor:          Theme.highlightFromColor(hyColor, Theme.ColorScheme)
    //readonly property color secondaryHylightColor: Theme.secondaryHighlightFromColor(hyColor, Theme.ColorScheme)
    //readonly property color dimmerHylightColor:    Theme.highlightDimmerFromColor(hyColor, Theme.ColorScheme)
    readonly property color logoColor:             Theme.rgba(hyColor, Theme.OpacityFaint)

    Connections {
        target: app
        onCoverMessagesChanged: messageView.model = app.coverMessages
    }

    Icon {
        z: -1
        source: Qt.resolvedUrl("./hydrogen.svg" + "?" + logoColor)
        anchors.horizontalCenter: parent.left
        anchors.verticalCenter: parent.bottom
        height: visible ? parent.height : 0
        fillMode: Image.PreserveAspectFit
        opacity: visible ? 0.2 : 0.0
        Behavior on opacity { FadeAnimator { duration: 1200 } }
        //Behavior on height  { PropertyAnimation { duration: 1200 ; easing.type: Easing.InBounce } }
    }
    Label {
        id: nameLabel
        text: qsTr("Hydrogen")
        x: (parent.width  - (width +  Theme.paddingLarge))
        y: visible ? (parent.height - (height + Theme.paddingSmall*3)) : parent.height + height
        //y: visible ? (Theme.paddingSmall*3) : parent.height + height
        font.pixelSize: Theme.fontSizeLarge
        color:   visible ? Theme.secondaryColor : hylightColor
        Behavior on color { ColorAnimation { duration: 2400 } }
        //Behavior on y { PropertyAnimation { duration: 800 ; easing.type: Easing.OutQuad} }
        Behavior on y { PropertyAnimation { duration: 1600 ; easing.type: Easing.OutQuad} }
    }
    Column { id: messageView
        property alias model: rep.model
        visible: titleLabel.length > 0
        x: visible ? Theme.horizontalPageMargin : parent.width + width
        y: nameLabel.height+Theme.paddingSmall
        Behavior on x { PropertyAnimation { duration: 800 ; easing.type: Easing.OutQuad} }
        width: parent.width - Theme.horizontalPageMargin
        height: parent.height - (coverAction.height + nameLabel.height)
        //anchors.top: nameLabel.bottom
        //anchors.horizontalCenter: parent.horizontalCenter
        Label { id: titleLabel
            text: (app.coverTitle) ? app.coverTitle : ""
            width: parent.width
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
            wrapMode: Text.Wrap
        }
        Repeater { id: rep
            delegate: Label {
                text: modelData
                font.pixelSize: Theme.fontSizeTiny*0.8
                wrapMode: Text.NoWrap
                truncationMode: TruncationMode.Fade
                width: ListView.view.width
            }
        }
    }

    CoverActionList {
        id: coverAction
        CoverAction {
            iconSource: "image://theme/icom-cover-sync"
        }
        CoverAction {
            iconSource: "image://theme/icom-cover-message"
        }
        CoverAction {
            iconSource: "image://theme/icom-cover-new"
        }
    }
}
