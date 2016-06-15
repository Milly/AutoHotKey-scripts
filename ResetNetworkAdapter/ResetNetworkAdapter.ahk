;=====================================================================
; ResetNetworkAdapter
;   Last Changed: 28 Oct 2015
;=====================================================================

#NoTrayIcon

interface = %1%
if (interface != "") {
    set_interface(interface, "disabled")
    Sleep, 3000
    set_interface(interface, "enabled")
}
ExitApp

set_interface(interface, stat) {
    RunWait, netsh.exe interface set interface %interface% %stat%, Hide
}
