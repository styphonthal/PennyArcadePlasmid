import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import QtQuick.Controls 2.15
import "../code/logic.js" as Logic
import QtQuick.Layouts

PlasmoidItem {
    width: 1000
    height: width / 2.4

    property string currentDate: ""
    property string currentImage: ""
    property string currentTitle: ""
    property string previousComicUrl: ""  // Added this property to store the previous comic URL

    Timer {
        id: initialLoadTimer
        interval: 100
        repeat: false
        onTriggered: loadComic("")
    }

    Component.onCompleted: {
        initialLoadTimer.start()
    }

    function loadComic(date) {
        Logic.fetchComic(date).then(
            function (comic) {
                currentImage = comic.imageUrl;
                currentTitle = comic.title;
                if (!date) {
                    currentDate = new Date().toISOString().split("T")[0];
                } else {
                    currentDate = date;
                }
                // Set the previous comic URL
                previousComicUrl = comic.previousComicUrl;
            },
            function (error) {
                console.log("Failed to fetch comic:", error);
            }
        );
    }

    function loadPreviousComic() {
        console.log("main loadprevious function");
        if (previousComicUrl) {
            Logic.fetchComic("", true, previousComicUrl).then(
                function (comic) {
                    currentImage = comic.imageUrl;
                    currentTitle = comic.title;
                    currentDate = comic.url.split("/").pop();  // Extract the date from the comic URL
                    previousComicUrl = comic.previousComicUrl;
                },
                function (error) {
                    console.log("Failed to load previous comic:", error);
                }
            );
        } else {
            console.log("No previous comic URL available");
        }
    }

    ColumnLayout {
        width: parent.width
        height: parent.height

        spacing: 0

        Image {
            source: currentImage
            Layout.fillWidth: true
            Layout.fillHeight: true
            fillMode: Image.PreserveAspectFit

            Layout.margins: 0  // Remove margins around the image (no padding)
            Layout.topMargin: 0   // Remove margin above the image
            Layout.bottomMargin: 0 // Remove margin below the image
        }

        Text {
            width: parent.width
            height: contentHeight
            text: currentTitle
            font.pixelSize: 20
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.margins: 0  // Remove margins around the text
            Layout.topMargin: 0   // Remove margin above the text
            Layout.bottomMargin: 0 // Remove margin below the text
            Layout.alignment: Qt.AlignHCenter
        }

        Row {
            spacing: 5

            Layout.alignment: Qt.AlignHCenter  // Center the button
            Button {
                text: "Previous"
                onClicked: {
                    console.log("Previous button clicked");
                    loadPreviousComic();
                }
            }
        }
    }
}
