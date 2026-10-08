pragma Singleton
import QtQuick 2.15

// Offline hostname fallback. install.sh rewrites this file using /etc/hostname.
// Main.qml still prefers live /etc/hostname at greeter runtime.
QtObject {
    property string hostname: ""
    property string runes: ""
}
