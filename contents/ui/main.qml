import QtQuick
import org.kde.plasma.plasmoid
import QtQuick.Controls
import "../code/logic.js" as Logic
import QtQuick.Layouts
import QtCore
import org.kde.plasma.core as PlasmaCore


PlasmoidItem {
    width: 500
    height: width / 1.5


    Plasmoid.backgroundHints: plasmoid.configuration.transparentBackground ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.Background


    property string currentDate: ""
    property string currentImage: ""
    property string currentTitle: ""
    property string previousComicUrl: ""
    property string nextComicUrl: ""
    property string comicDescription: ""

    Settings {
        id: appSettings
        property string lastCheckedDate: ""
    }

    Timer {
        id: initialLoadTimer
        interval: 10
        repeat: false
        onTriggered: loadComic("")
    }

    Timer {
        id: dailyCheckTimer
        interval: 24 * 60 * 60 * 1000 // 24 hours in milliseconds
        repeat: true
        onTriggered: checkForNewComicDaily()
    }

    Component.onCompleted: {
        initialLoadTimer.start()
        dailyCheckTimer.start()
    }

    function loadComic(date) {
        const today = new Date();
        const todayFormatted = today.toISOString().split("T")[0].split("-").join("/"); // Format as YYYY/MM/DD
        const lastCheckedDate = appSettings.lastCheckedDate || todayFormatted;

        console.log("Today's date:", todayFormatted);
        console.log("Last checked date:", lastCheckedDate);

        if (date) {
            // If a date is provided, load that specific comic
            Logic.fetchComic(date, false, previousComicUrl).then(
                function (comic) {
                    setComicData(comic, date);
                },
                function (error) {
                    console.log("Failed to fetch comic:", error);
                }
            );
        } else if (lastCheckedDate !== todayFormatted) {
            // If it's a new day, load the last release comic
            console.log("New day detected. Fetching the latest comic...");

            const lastReleaseDate = getLastReleaseDate(today); // Get last release date based on today's day
            console.log("Calculated Last Release Date:", lastReleaseDate);

            Logic.fetchComic(lastReleaseDate, false, previousComicUrl).then(
                function (comic) {
                    setComicData(comic, lastReleaseDate);
                    appSettings.lastCheckedDate = lastReleaseDate; // Update last checked date
                },
                function (error) {
                    console.log("Failed to fetch the latest comic:", error);
                }
            );
        } else {
            // Load cached comic for today
            console.log("Loading the previously fetched comic for today...");
            Logic.fetchComic(lastCheckedDate, false, previousComicUrl).then(
                function (comic) {
                    setComicData(comic, lastCheckedDate);
                },
                function (error) {
                    console.log("Failed to fetch comic:", error);
                }
            );
        }
    }



    function getLastReleaseDate(today) {
        // Ensure today is at midnight local time to avoid timezone issues
        today.setHours(0, 0, 0, 0);  // Set the time to 00:00:00 for a clean comparison
        console.log("Today (reset to midnight):", today);

        const releaseDays = [1, 3, 5]; // Monday, Wednesday, Friday (Index 0 = Sunday, so 1 = Monday)
        let currentDay = today.getDay();

        // Check if today is a release day (Monday, Wednesday, or Friday)
        if (releaseDays.includes(currentDay)) {
            const formattedDate = today.toISOString().split("T")[0].split("-").join("/"); // Convert to YYYY/MM/DD format
            console.log("Calculated Last Release Date (today is a release day):", formattedDate);
            return formattedDate;
        }

        // Otherwise, calculate the previous release day
        let daysToSubtract = Infinity;  // Start with a very large number
        for (let releaseDay of releaseDays) {
            // Calculate how many days back the previous release day is
            const daysDifference = (currentDay - releaseDay + 7) % 7;
            if (daysDifference > 0 && daysDifference < daysToSubtract) {
                daysToSubtract = daysDifference;
            }
        }

        // Subtract the days to get the last release day
        today.setDate(today.getDate() - daysToSubtract);
        const formattedDate = today.toISOString().split("T")[0].split("-").join("/"); // Convert to YYYY/MM/DD format
        console.log("Calculated Last Release Date (previous release day):", formattedDate);
        return formattedDate;
    }


    function loadPreviousComic() {
        console.log("main loadprevious function");
        if (previousComicUrl) {
            Logic.fetchComic("", true, previousComicUrl).then(
                function (comic) {
                    currentImage = comic.imageUrl;

                    currentTitle = comic.title.replace(/- Penny Arcade$/, "").trim(); // trim title



                    // Extract the date from the comic URL, ignoring query parameters
                    const regex = /(\d{4})\/(\d{2})\/(\d{2})/;  // Regular expression to capture date in YYYY/MM/DD format
                    const match = comic.url.match(regex);

                    if (match) {
                        const comicDate = match[0];  // Get the date portion (YYYY/MM/DD)
                        currentDate = comicDate;  // Set the correct published date
                        console.log("Updated Current Date:", currentDate);
                    } else {
                        console.log("Failed to extract date from previous comic URL:", comic.url);
                    }


                    console.log("Current Date:", currentDate);

                    previousComicUrl = comic.previousComicUrl;
                    nextComicUrl = comic.nextComicUrl;
                    setComicData(comic, currentDate);
                },
                function (error) {
                    console.log("Failed to load previous comic:", error);
                }
            );
        } else {
            console.log("No previous comic URL available");
        }
    }


    function loadNextComic() {
        console.log("main loadnext function");

        if (nextComicUrl) {


            // Extract the full path YYYY/MM/DD/comicname from nextComicUrl
            const nextComicPath = nextComicUrl.split('/').slice(-4).join('/');  // Extract YYYY/MM/DD/comicname

            console.log("MIDWAY loadnext Request URL:", nextComicUrl);
            console.log("Extracted next comic path:", nextComicPath);

            // Fetch the next comic using the extracted date and passing the nextComicUrl as the URL
            Logic.fetchComic(nextComicPath, false, previousComicUrl, true).then(
                function (comic) {
                    // Update comic data after fetching the next comic
                    currentImage = comic.imageUrl;

                    currentTitle = comic.title.replace(/- Penny Arcade$/, "").trim(); // trim title



                    // Extract the date from the comic URL, ignoring query parameters
                    const regex = /(\d{4})\/(\d{2})\/(\d{2})/;  // Regular expression to capture date in YYYY/MM/DD format
                    const match = comic.url.match(regex);

                    if (match) {
                        const comicDate = match[0];  // Get the date portion (YYYY/MM/DD)
                        currentDate = comicDate;  // Set the correct published date
                        console.log("Updated Current Date:", currentDate);
                    } else {
                        console.log("Failed to extract date from previous comic URL:", comic.url);
                    }


                    console.log("Current Date:", currentDate);

                    previousComicUrl = comic.previousComicUrl;
                    nextComicUrl = comic.nextComicUrl;
                    setComicData(comic, currentDate);

                },

                function (error) {
                    console.log("Failed to load next comic:", error);
                }
            );
        } else {
            console.log("No next comic URL available");
        }
    }



    function setComicData(comic, date) {
        currentImage = comic.imageUrl;
        currentTitle = comic.title.replace(/- Penny Arcade$/, "").trim(); // trim title
        currentDate = date;
        console.log("Current Date:", currentDate);
        previousComicUrl = comic.previousComicUrl;
        nextComicUrl = comic.nextComicUrl;
        comicDescription = comic.description;
    }




    ColumnLayout {
        width: parent.width
        height: parent.height

        spacing: 0  // No extra space between items

        // "Penny Arcade" title
        Text {
            text: "Penny Arcade"
            font.pixelSize: 40
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true  // Take up the full width of the parent
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 0
            Layout.bottomMargin: 5
            Layout.leftMargin: 0
            Layout.rightMargin: 0
        }

        Image {
            source: currentImage
            Layout.fillWidth: true
            Layout.fillHeight: true
            fillMode: Image.PreserveAspectFit
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.topMargin: 0
            Layout.bottomMargin: 0
        }

        // Comic title
        Text {
            width: parent.width
            height: contentHeight
            text: currentTitle
            font.pixelSize: 20
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.fillWidth: true  // Take up full width, avoid large side margins
            Layout.fillHeight: true
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.topMargin: 0
            Layout.bottomMargin: 0
        }

        // "Published" Date Text
        Text {
            width: parent.width
            height: contentHeight
            text: "Published: " + currentDate
            font.pixelSize: 14
            color: "lightgray"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true  // Take up full width, avoid large side margins
            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.topMargin: 0
            Layout.bottomMargin: 0
        }

        Row {
            spacing: 5
            Layout.alignment: Qt.AlignHCenter

            // Previous button
            Button {
                enabled: previousComicUrl !== ""  // Disable when there's no previous comic
                onClicked: {
                    console.log("Previous button clicked");
                    loadPreviousComic();

                }
                background: Rectangle {
                    color: enabled ? "lightgreen" : "gray" // Set background color based on enabled state
                    radius: 5
                }

                contentItem: Text {
                    text: "◀"  // Black Right Arrow
                    font.family: "Noto Sans"  // Or any available system font
                    font.pixelSize: 24
                    color: "white"

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

            // Next button
            Button {


                enabled: nextComicUrl !== null && nextComicUrl !== ""
                onClicked: {
                    console.log("Next button clicked");
                    loadNextComic();
                }
                background: Rectangle {
                    color: enabled ? "lightgreen" : "gray" // Set background color based on enabled state
                    radius: 5
                }


                contentItem: Text {
                    text: "▶"  // Black Right Arrow
                    font.family: "Noto Sans"  // Or any available system font
                    font.pixelSize: 24
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }


        } // end of row


        Button {
            text: "Commentary"
            width: 20
            enabled: comicDescription && comicDescription.length > 0  // Enable only if description exists
            onClicked: commentaryPopup.open()
            Layout.alignment: Qt.AlignHCenter

            Layout.leftMargin: 0
            Layout.rightMargin: 0
            Layout.topMargin: 5
            Layout.bottomMargin: 0
            background: Rectangle {
                color: enabled ? "lightgreen" : "gray"  // Change background color
                radius: 5
            }

            contentItem: Text {
                text: parent.text
                color: "black"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

    } //end of mainpage layout

    Popup {
        id: commentaryPopup
        width: 400
        height: 400
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color: "white"
            border.color: "black"
            radius: 8
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            spacing: 5
            anchors.margins: 20

            // Title
            Text {
                text: "Commentary"
                font.bold: true
                font.pixelSize: 18
                color: "black"
                Layout.alignment: Qt.AlignHCenter
            }

            // Scrollable Area for Commentary Text
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ScrollView content container
                Column {
                    width: parent.width

                    // Text component for the commentary
                    Text {
                        id: commentaryText
                        text: {

                            // Replace double newlines with HTML <p> tags to preserve paragraph structure
                            let formattedText = comicDescription ? comicDescription.replace(/\n\n/g, "</p><p>").trim() : "No commentary available.";
                            return "<p>" + formattedText + "</p>";
                        }
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                        color: "black"
                        font.pixelSize: 14
                        width: parent.width  // Text should take the full width of the ScrollView
                    }
                }

                // Vertical scrollbar to allow scrolling if text is cut off
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn  // Show the scrollbar when needed
                }
            }

            // Close Button
            Button {
                text: "Close"
                Layout.alignment: Qt.AlignHCenter
                onClicked: commentaryPopup.close()
            }
        }
    }





} //end of main.qml
