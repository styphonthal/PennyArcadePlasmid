import QtQuick 2.15
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.CheckBox {
    text: i18n("Transparent Background")
    checked: plasmoid.configuration.transparentBackground
    onCheckedChanged: plasmoid.configuration.transparentBackground = checked
}
