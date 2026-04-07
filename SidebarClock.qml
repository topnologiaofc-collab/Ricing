import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

Item {
    id: root
    property bool open: false
    property date monthDate: new Date()
    property date selectedDate: new Date()
    property var eventsByDate: ({
        "2026-04-05": [{"t":"Standup","h":"09:00","c":"#7c3aed"}, {"t":"Almoço c/ Ana","h":"12:30","c":"#0ea5e9"}],
        "2026-04-07": [{"t":"Deploy prod","h":"18:00","c":"#ef4444"}],
        "2026-04-12": [{"t":"Consulta médica","h":"10:00","c":"#22c55e"}],
        "2026-04-20": [{"t":"Happy hour","h":"19:00","c":"#f59e0b"}]
    })
    signal requestCloseOthers(string who)
    property date nowTime: new Date()

    width: 104
    implicitHeight: clockButton.implicitHeight

    function iso(d) {
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, "0");
        const da = String(d.getDate()).padStart(2, "0");
        return `${y}-${m}-${da}`;
    }

    function monthTitle(d) {
        const months = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"];
        return `${months[d.getMonth()]} ${d.getFullYear()}`;
    }

    Rectangle {
        id: clockButton
        anchors.horizontalCenter: parent.horizontalCenter
        width: 96
        height: 34
        radius: 10
        color: mouse.containsMouse || root.open ? Qt.rgba(124/255,58/255,237/255,0.15) : "transparent"
        implicitHeight: 34

        Row {
            id: col
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: Qt.formatTime(root.nowTime, "hh:mm")
                color: Theme.textPrimary
                font.pixelSize: 21
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle { width: 2; height: 18; radius: 1; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: `${Qt.locale("pt_BR").dayName(root.nowTime.getDay(), Locale.ShortFormat).slice(0,3).toUpperCase()} ${Qt.formatDate(root.nowTime, "dd")}`
                color: Theme.accent
                font.pixelSize: 13
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.open = !root.open;
                if (root.open)
                    root.requestCloseOthers("calendar");
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.nowTime = new Date()
    }

    PopupWindow {
        id: popup
        visible: root.open
        color: "transparent"
        anchor.window: root.QsWindow.window
        anchor.rect.x: Math.max(6, root.mapToItem(null, 0, 0).x - 4)
        anchor.rect.y: root.mapToItem(null, 0, 0).y + clockButton.height + 8
        implicitWidth: Theme.popupWidth
        implicitHeight: 332

        Rectangle {
            anchors.fill: parent
            radius: Theme.popupRadius
            color: Qt.rgba(11/255, 15/255, 25/255, 0.96)
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: monthTitle(root.monthDate); color: Theme.textPrimary; font.pixelSize: 12; font.weight: Font.Medium }
                    Item { Layout.fillWidth: true }
                    Repeater {
                        model: ["‹", "›"]
                        delegate: Rectangle {
                            width: 22
                            height: 22
                            radius: 6
                            color: navMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                            Text { anchors.centerIn: parent; text: modelData; color: "#94a3b8"; font.pixelSize: 12 }
                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    const delta = index === 0 ? -1 : 1;
                                    root.monthDate = new Date(root.monthDate.getFullYear(), root.monthDate.getMonth() + delta, 1);
                                }
                            }
                        }
                    }
                }

                GridLayout {
                    columns: 7
                    Layout.fillWidth: true
                    Repeater {
                        model: ["D","S","T","Q","Q","S","S"]
                        delegate: Text { text: modelData; color: "#334155"; font.pixelSize: 8; font.weight: Font.Medium; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
                    }
                }

                GridLayout {
                    id: dayGrid
                    columns: 7
                    rowSpacing: 1
                    columnSpacing: 1
                    Layout.fillWidth: true

                    Repeater {
                        model: 42
                        delegate: Rectangle {
                            property date firstDay: new Date(root.monthDate.getFullYear(), root.monthDate.getMonth(), 1)
                            property int firstWeekDay: firstDay.getDay()
                            property int daysInMonth: new Date(root.monthDate.getFullYear(), root.monthDate.getMonth() + 1, 0).getDate()
                            property int daysInPrev: new Date(root.monthDate.getFullYear(), root.monthDate.getMonth(), 0).getDate()
                            property int dayN: index - firstWeekDay + 1
                            property bool inMonth: dayN >= 1 && dayN <= daysInMonth
                            property int shownDay: inMonth ? dayN : (dayN < 1 ? daysInPrev + dayN : dayN - daysInMonth)
                            property date effectiveDate: new Date(root.monthDate.getFullYear(), root.monthDate.getMonth() + (dayN < 1 ? -1 : (dayN > daysInMonth ? 1 : 0)), shownDay)
                            property bool isToday: root.iso(effectiveDate) === root.iso(new Date())
                            property bool selected: root.iso(effectiveDate) === root.iso(root.selectedDate)
                            property bool hasEvent: root.eventsByDate[root.iso(effectiveDate)] !== undefined

                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            radius: 6
                            color: isToday ? Theme.accent : (selected ? Qt.rgba(124/255,58/255,237/255,0.22) : hover.containsMouse ? Qt.rgba(1,1,1,0.07) : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: shownDay
                                color: inMonth ? (isToday ? "white" : selected ? "#a78bfa" : Theme.textMuted) : "#1e293b"
                                font.pixelSize: 9
                                font.weight: isToday ? Font.Bold : selected ? Font.Medium : Font.Normal
                            }
                            Rectangle {
                                visible: hasEvent
                                width: 3; height: 3; radius: 1.5
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                color: isToday ? Qt.rgba(1,1,1,0.8) : Theme.accent
                            }
                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.selectedDate = parent.effectiveDate
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.07) }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: root.eventsByDate[root.iso(root.selectedDate)] || []
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            radius: 7
                            color: Qt.rgba(1,1,1,0.04)
                            implicitHeight: 30
                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 7
                                Rectangle { width: 5; height: 5; radius: 2.5; color: modelData.c; anchors.verticalCenter: parent.verticalCenter }
                                Column {
                                    Text { text: modelData.t; color: Theme.textPrimary; font.pixelSize: 10; font.weight: Font.Medium }
                                    Text { text: modelData.h; color: Theme.textMuted; font.pixelSize: 8 }
                                }
                            }
                        }
                    }
                    Text {
                        visible: (root.eventsByDate[root.iso(root.selectedDate)] || []).length === 0
                        text: "Sem eventos"
                        color: "#334155"
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
