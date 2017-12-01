import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Window 2.2

ApplicationWindow {
    id: window
    visible: true
    width: isDesktop ? (Screen.width/2.5) : Screen.width; height: isDesktop ? (Screen.height * 0.90) : Screen.height
    title: currentPage ? (currentPage.title + " - " + Config.applicationName) : (Config.applicationName + " - " + Config.applicationDescription)
    onClosing: buttonPressed(close)

    Component.onCompleted: {
        setActivePage()
        // when runnig in desktop mode, centralize the application window.
        if (isDesktop) {
            setX(Screen.width / 2 - width / 2)
            setY(Screen.height / 2 - height / 2)
        }
    }

    // a flag to check if the app is running in android
    readonly property bool isAndroid: Qt.platform.os === "android"

    // a flag to check if the app is running in desktop (linux or osx)
    readonly property bool isDesktop: !isIOS && !isAndroid

    // a flag to check if the app is running in iOS
    readonly property bool isIOS: Qt.platform.os === "ios"

    // keeps the home/index page saved by some plugin
    readonly property string homePageUrl: App.readSetting("homePageUrl", App.SettingTypeString)

    // keeps a instance of MessageDialog with native look and feel,
    // the instance will be created dinamically by platform type.
    property QtObject dialog

    // swipe view is used when app set 'usesTabBar' to true in config.json.
    // If true, the app pages can be changed by swiping or
    // using the TabBar buttons put in the bottom of window.
    property SwipeView swipeView

    // keeps a reference to current visible page on the window.
    property QtObject currentPage: Config.usesTabBar ? swipeView.currentItem : pageStack.currentItem

    // handle the Android backButton, prevent close the app with some tricks.
    // to more details take a look in mainSignals.buttonPressed().
    signal buttonPressed(var button)
    onButtonPressed: mainSignals.buttonPressed(button)

    // the first function called by window to set the first page to the user.
    // to more details take a look in mainSignals.setActivePage()
    signal setActivePage()
    onSetActivePage: mainSignals.setActivePage()

    // show alert dialog with system platform look end feel.
    // to more details take a look in mainSignals.alert(...)
    signal alert(string title, string message, var acceptCallback, var rejectCallback)
    onAlert: mainSignals.alert(title, message, acceptCallback, rejectCallback)

    // keeps the window signals, modularized to reduce the Main.qml size. :)
    MainSignals {
        id: mainSignals
    }

    // load a Binding object to create a bind with ToolBar and current active page in stackView.
    Loader {
        active: true; asynchronous: true
        sourceComponent: Binding {
            target: window.header
            property: "visible"
            value: pageStack.depth && pageStack.currentItem && pageStack.currentItem.showToolBar
        }
    }

    // load a Binding object to create a bind with window.currentPage and swipeview and PageStack.
    // if app uses swipeView, the currentItem point to currentPage in swipeView, otherwise point to
    // currentPage in StackView. Some QML objects make binds with window.currentPage (toolbar).
    Loader {
        active: true; asynchronous: true
        sourceComponent: Binding {
            target: window
            property: "currentPage"
            value: Config.usesTabBar && !pageStack.depth ? swipeView.currentItem : pageStack.currentItem
        }
    }

    // load a Binding object to create a bind with TabBar and current active page
    // in swipeView. The TabBar, after created, keeps a reference to window.footer and needs
    // to be visible when pageStack is empty and current page set showTabBar to true.
    Loader {
        active: Config.usesTabBar && user.isLoggedIn; asynchronous: true
        sourceComponent: Binding {
            when: user.isLoggedIn && Config.usesTabBar
            target: window.footer
            property: "visible"
            value: !pageStack.depth && swipeView.currentItem && swipeView.currentItem.showTabBar
        }
    }

    // load the main TabBar to show pages buttons, used with swipeview if "usesTabBar" is true
    // in config.json. The app will be uses the swipeView + tabBar to swap the application pages.
    Loader {
        active: Config.usesTabBar && user.isLoggedIn; asynchronous: false
        source: "TabBar.qml"
        onLoaded: footer = item
    }

    // load the main toolbar if user is logged in. The toolbar is used to show a button
    // to open the navigation drawer (if "usesDrawer" is defined to true in config.json)
    // and dynamic buttons defined by each page, for some actions like show a submenu or search button.
    Loader {
        active: user.isLoggedIn; asynchronous: false
        source: "ToolBar.qml"
        onLoaded: header = item
    }

    // load the system menu to show pages options to the user.
    // The Menu is a instance of QML Drawer with some customizations.
    Loader {
        active: Config.usesDrawer && user.isLoggedIn; asynchronous: true
        source: "Menu.qml"
    }

    // load a new instance of messages dialog component,
    // using the platform name for best look and fell appearence.
    Loader {
        active: true; asynchronous: false
        source: isIOS ? "IOSDialog.qml" : "AndroidDialog.qml"
        onLoaded: dialog = item
    }

    // to listeners plugins get access to user profile data or currentPage,
    // the listeners objects needs to be loaded in this context.
    Loader {
        active: user.isLoggedIn; asynchronous: true
        source: "ListenersLoader.qml"
    }

    // load a dynamic SwipeView container as the main page container,
    // if "usesTabBar" (from config.json) was defined to true.
    Loader {
        anchors.fill: active ? parent : undefined
        active: Config.usesTabBar; asynchronous: false
        sourceComponent: SwipeView {
            id: swipeView
            visible: Config.usesTabBar && pageStack.depth === 0
            anchors.fill: visible ? parent : undefined
            currentIndex: footer ? footer.currentIndex : 0
        }
        onLoaded: { window.swipeView = item }
    }

    // handle android back button,
    // used to pop pages when is pressed.
    Item {
        Keys.onBackPressed: buttonPressed(event)
    }

    // the user profile manager.
    // All qml components can read the user information from "user" reference.
    UserProfile {
        id: user
    }

    // handle the android Snackbar widget,
    // used to show some application warnings.
    Snackbar {
        id: snackbar
        z: 1
    }

    // handle the android Toast widget,
    // used to show some application information messages.
    Toast {
        id: toast
    }

    // the main page container, is aways available and QML pages can push or pop pages
    // using "pageStack" reference. This component has a simple customization, where
    // prevent push a new page if already exists in the stack.
    PageStack {
        id: pageStack
    }
}