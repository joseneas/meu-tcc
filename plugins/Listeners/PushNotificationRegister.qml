import QtQuick 2.8

import "qrc:/qml/"

Item {
    id: rootItem
    objectName: "PushNotificationRegister.qml"

    property string token

    // Component.onCompleted: console.log(rootItem.objectName + " created!")
    // Component.onDestruction: console.log(rootItem.objectName + " onDestruction!")

    signal sendTokenToServer()
    onSendTokenToServer: {
        if (!user.profile.id)
            return
        if (!rootItem.token)
            rootItem.token = Utils.readFirebaseToken()
        if (!rootItem.token || user.profile.push_notification_token && user.profile.push_notification_token === rootItem.token) {
            rootItem.destroy()
            return
        }
        var params = JSON.stringify({
            "id": user.profile.id,
            "push_notification_token": token
        })
        requestHttp.post("/token_register/", params)
        params = ""
    }

    RequestHttp {
        id: requestHttp
        onFinished: {
            if (statusCode === 200) {
                user.setProperty("push_notification_token", rootItem.token)
                App.removeSetting(Config.events.pushNotificationToken)
                rootItem.destroy()
            }
        }
    }

    // this action is necessary when firebase token is generated or updated after user logged in.
    // the token will be registered in another application process started by firebase service.
    // when token are updated, if user is logged in, we need to send the token to webservice.
    Connections {
        target: App
        onEventNotify: {
            // signal signature: eventNotify(QString eventName, QVariant eventData)
            if (eventName === Config.events.pushNotificationToken) {
                rootItem.token = eventData
                sendTokenToServer()
            } else if (eventName === Config.events.userProfileChanged) {
                rootItem.token = App.readSetting(Config.events.pushNotificationToken, App.STRING)
                sendTokenToServer()
            }
        }
    }
}