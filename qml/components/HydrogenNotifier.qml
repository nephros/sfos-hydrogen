import QtQuick 2.2      // not 2.0, because Instantiator
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0

/*
 * This is a rather overly complicated wrapper around the Nemo.Notifications plugin.
 *
 * Basic mode of operation internally is that we use a simple ListModel
 * containting UIDs, and feed that to a QML Instatiator (the "factory").
 *
 * factory will create Notification objects for us, which we either fatten up
 * with properties, or publish as-is.
 *
 * Users (code) can either use the quick* functions, or the fullblown
 * addNotification() and updateNotification() functions. Users of addNotification()
 * are expected to record the returned message UID if they want to later handle
 * their published message.
 *
 * Complex notifications should be possible by using something like:
 *     const hold = true
 *     const m_id = addNotification( [...], hold)
 *     var new_props = {
 *       // set any Notification properties here
 *       "icon": "image://theme/icon-m-warning"
 *     }
 *     updateNotification(m_id, new_props, hold)
 *     publishNotification(m_id)
*/

Item { id: root
    /*! ListModel to serve as an input to the factory */
    property alias messages: factory.model

    /*! Emitted when a Notification hsa been published */
    signal messagePublished(string msgid)

    /*! Holds the ID of the first published message so we can do "sticky" notifications */
    property int stickyId: 0

    /*!
     * Creates and publishes a new notification.
     * Convenience function to quickly publish a notification.
     */
    function quickNotification( message ) { addNotification( undefined, message, undefined, message, undefined, undefined, false ) }

    /*!
     * Creates and publishes a new notification.
     * Convenience function to quickly publish a notification.
     */
    function quickNumberedNotification( message, count ) { addNotification( undefined, message, undefined, message, count, undefined, false ) }


    /*!
     * Creates and publishes a new notification.
     *
     * At least the shortMessage parameter should be supplied.
     * If uid is specified, it can be used in removeNotification later.
     *
     * Both "title" parameters default to "Notification" if not specified.
     *
     * The count parameter will be passed as itemCount property to the Notification
     *
     * If hold is set, the Notification is not published immediately, and must
     * be published later by calling publishNotification()
     */
    function addNotification( shortTitle, shortMessage,
                              title, message,
                              count,
                              uid,
                              hold
                            ) {
        // we can't write to uid, so copy it to a local variable
        const msgid = (uid) ? uid : Qt.md5([ Date.now(), Math.random(), title, message, shortTitle, shortMessage, count].join())

        // wait for the instantiator to create the object, set properties through function
        var conn = factory.objectAdded.connect(createNewNotification)

        // add new thing to model, this should trigger creation of a new
        // notification.
        messages.append({"mid": msgid})
        return msgid

        /* Set properties and optionally publish
         * need a named function here so we can disconnect() again.
         */
        function createNewNotification(idx, obj) {
            console.assert(shortMessage, "Warning: we should have at least a message body")

            obj.summary        = (title)      ? title      : qsTr("Notification")
            obj.previewSummary = (shortTitle) ? shortTitle : qsTr("Notification")

            if (message)        obj.body           = message
            if (shortMessage)   obj.previewBody    = shortMessage
            if (count)          obj.itemCount      = count
            // store our id for sending back on notification click
            obj.internalId = msgid

            if (!hold) {
                obj.publish()
                messagePublished(msgid)
            }
            // disconnect ourselves again.
            factory.objectAdded.disconnect(createNewNotification)
        }

    }

    /*! Publishes a Notification
     * uid is the internal uid from the "messages" model
     */
    function publishNotification(uid) {
        for (var i = 0; i<messages.count; i++) {
            var o = messages.get(i);
            if (o.mid === uid) {
                var n = factory.objectAt(i)
                console.assert(n, "BUG: retrieved an invalid object from factory.")
                if (appConfig.stickyNotifications && (stickyId != 0)) {
                    n.replacedId = stickyId
                }
                console.debug("Publishing notification", uid)
                n.publish()
                if (appConfig.stickyNotifications && (stickyId == 0)) {
                    // after publishing, record the replacesId so we can overwrite it
                    stickyId = n.replacedId
                    console.assert(stickyId != 0, "WARNING: Couldn't get a valid replacesId to store.")
                }
                messagePublished(uid)
            }
        }
    }

    /*! Updates Notification contents
     * uid is the internal uid from the "messages" model
     * params is an object having the updated parameters
     *
     * If hold is true, changes will be published immediately, otherwise
     * publishNotification() must be called for them to appear.
     */
    function updateNotification(uid, parms, hold) {
        for (var i = 0; i<messages.count; i++) {
            var o = messages.get(i);
            if (o.mid === uid) {
                // if any of the keys in parms exists in the notification,
                // update the notification
                var n = factory.objectAt(i)
                console.assert(n, "BUG: retrieved an invalid object from factory.")
                var keys = Object.keys(parms)
                keys.forEach(function(k) {
                    if (n[k]) { n[k] = parms[k] }
                })
                // update published notification:
                if (!hold) {
                    n.publish()
                    messagePublished(uid)
                }
            }
        }
    }

    /*! Removes a Notification.
     *
     * looks for the uid in the messages model, removes it if found
     * This should destroy the object in the factory, which will delete the message
     */
    function removeNotification(uid) {
        for (var i = 0; i<messages.count; i++) {
            var o = messages.get(i);
            if (o.mid === uid) messages.remove(i,1)
        }
    }

    /*! Removes all Notifications and restarts the factory. */
    function removeAll() {
        factory.active = false;
        messages.clear();
        factory.countChanged.connect(function() {
            if (!factory.active && (factory.count == 0)) factory.active = true;
        })
    }

    Instantiator { id: factory
        asynchronous: true
        delegate: template
        model: ListModel{}

        // remove notifications from eventview on destruction
        onObjectRemoved: function(idx, obj) {
            obj.close()
        }
    }

    /*! Template Notification for the Instantiator.
     *
     * Sets up all the message boilerplate, as well as remote "actions" to be
     * triggered when the user iteracts with a published notification.
     */
    Component { id: template; Notification {
         property string internalId
         category: "im.received"
         appName: qsTr("Hydrogen")
         appIcon: "image://theme/harbour-hydrogen"
         //summary: "Notification summary"
         //body: "Notification body"
         //previewSummary: "Notification preview summary"
         //previewBody: "Notification preview body"
         //itemCount: 5
         //timestamp: "2013-02-20 18:21:00"
         remoteActions: [ {
             // invoked when the user clicks the notification item
             "name":     "default",
             "displayName": qsTr("Open Conversation"),
             "icon":     "icon-lock-chat",
             "service":  "org.github.hydrogen-sailfishos.harbour-hydrogen.hydrogen",
             "path":     "/hydrogen/ui",
             "iface":    "org.github.HydrogenSailfishOS.Hydrogen.ui",
             "method":   "fromNotification",
             "arguments": [ internalId, replacesId ]
         },
         {
             // invoked when the user clicks the app notification group
             "name": "app",
             "service":  "org.github.hydrogen-sailfishos.harbour-hydrogen.hydrogen",
             "path":     "/hydrogen/ui",
             "iface":    "org.github.HydrogenSailfishOS.Hydrogen.ui",
             "method":   "activate",
         } ]
         onClicked: console.log("Clicked")
         onClosed: console.log("Closed, reason: " + reason)
     }}

    /* ########## Internal testing stuff below ############# */

    function runTests() { testItem.runTests() }
    Item{ id: testItem
        function runTests() {
            var uid = Qt.md5(Math.random())
            console.debug("Notification test started")
            notifier.quickNumberedNotification( "Test Numbered Message", Math.floor(Math.random() * 25));
            notifier.quickNotification( "Quick Test" )
            notifier.addNotification( "Short Title", "Short Message",
                "Added Title", "Added Message",
                undefined,
                uid,
                false)
            testTimer.uid = uid
            testTimer.start()
        }
        Timer { id: testTimer
            property string uid
            repeat: false
            onTriggered: {
                console.debug("Notification test timer fired")
                notifier.updateNotification(uid, {
                    "summary":          "Updated Notification summary",
                    "body":             "Updated Notification body",
                    "previewSummary":   "Updated Notification preview summary",
                    "previewBody":      "Updated Notification preview body",
                })
                uid = Qt.md5(Math.random())
                // hold notification:
                notifier.addNotification( "Hold Short Title", "Hold Short Message",
                    "Hold Title", "Hold Message",
                    undefined,
                    uid,
                    true)
            testTimer2.uid = uid
            testTimer2.start()
            }
        }
        Timer { id: testTimer2
            property string uid
            interval: 2000
            repeat: false
            onTriggered: {
                console.debug("Notification test timer 2 fired")
                notifier.publishNotification(uid)
            }
        }
    }
}
