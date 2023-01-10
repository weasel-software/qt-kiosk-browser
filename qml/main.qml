/*
 * qt-kiosk-browser
 * Copyright (C) 2018
 * O.S. Systems Sofware LTDA: contato@ossystems.com.br
 *
 * SPDX-License-Identifier:     GPL-3.0
 */

import QtQuick 2.0
import QtQuick.Window 2.1
import QtWebEngine 1.4
import QtQuick.VirtualKeyboard 2.1

import Browser 1.0

Window {
    id: window

    visibility: Window.FullScreen
    visible: true
    color: "black"

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        let conf = "file:" + (Qt.application.arguments.slice(1).find(arg => !arg.startsWith("--")) || "settings.json");
        console.log("Loading configuration from '" + conf + "'");
        xhr.open("GET", conf);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.responseText.trim().length != 0) {
                    try {
                        var settings = JSON.parse(xhr.responseText);

                        if (typeof settings["ScreenSaverTimeout"] != "undefined") {
                            screenSaverTimer.interval = parseInt(settings["ScreenSaverTimeout"]);
                        }

                        if (typeof settings["RestartTimeout"] != "undefined") {
                            restartTimer.interval = parseInt(settings["RestartTimeout"]);
                        }

                        if (typeof settings["URL"] != "undefined") {
                            webView.url = settings["URL"];
                        }

                        if (typeof settings["Rotation"] != "undefined") {
                            webView.rotation = settings["Rotation"];
                            if (webView.rotation == 90 || webView.rotation == 270) {
                                webView.width = Screen.height;
                                webView.height = Screen.width;
                            }
                        }

                        for (var key in settings["WebEngineSettings"]) {
                            if (typeof webView.settings[key] == "undefined") {
                                console.error("Invalid settings property: " + key);
                                continue;
                            }

                            webView.settings[key] = settings["WebEngineSettings"][key];
                        }

                        if (typeof settings["SplashScreen"] != "undefined") {
                            splash.source = settings["SplashScreen"];
                        }

                        if (typeof settings["DisableContextMenu"] != "undefined") {
                            webView.disableContextMenu = settings["DisableContextMenu"];
                        }
                    } catch (e) {
                        console.error("Failed to parse settings file: " + e)
                    }
                }
            }
        }

        xhr.send();
    }

    WebEngineView {
        id: webView

        url: "http://www.ossystems.com.br"

        anchors.centerIn: parent
        visible: false

        property bool disableContextMenu: false

        onLoadingChanged: {
            if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                webView.visible = true;
                splash.visible = false;
            }
        }

        onContextMenuRequested: {
            request.accepted = disableContextMenu;
        }
    }

    Image {
        id: splash
        anchors.fill: parent
        visible: false

        onStatusChanged: {
            if (status === Image.Ready) {
                visible = true;
            }
        }
    }

    InputPanel {
        id: inputPanel

        y: Qt.inputMethod.visible ? parent.height - inputPanel.height : parent.height

        anchors.left: parent.left
        anchors.right: parent.right
    }

    Rectangle {
        id: screenSaver
        color: "black"
        visible: false
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent

            onClicked: {
                screenSaver.visible = false
            }
        }
    }

    InputEventHandler {
        onTriggered: {
            screenSaverTimer.restart();
        }
    }

    Timer {
        id: screenSaverTimer
        interval: 60000 * 20 // 20 minutes
        running: interval > 0
        repeat: false

        onTriggered: {
            if (this.interval > 0) {
                screenSaver.visible = true;
                restartTimer.start();
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 60000 * 3 // 3 minutes
        repeat: false

        onTriggered: Browser.restart()

        function start() {
            this.running = this.interval > 0;
        }
    }
}
