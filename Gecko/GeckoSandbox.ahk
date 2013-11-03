;=====================================================================
; Emacs keybinding
;   Last Changed: 3 Nov 2013
;=====================================================================

; #NoTrayIcon
#InstallKeybdHook
#UseHook

#IfWinActive,ahk_class MozillaWindowClass

^Tab::  parent_focus("{CtrlDown}{Tab}{CtrlUp}")
^+Tab:: parent_focus("{CtrlDown}{ShiftDown}{Tab}{ShiftUp}{CtrlUp}")
^l::    parent_focus("{CtrlDown}l{CtrlUp}")
^w::    parent_focus("{CtrlDown}w{CtrlUp}")

parent_focus(key) {
    ControlGetFocus, ctl
    If ( ctl = "GeckoFPSandboxChildWindow1" )
        ControlClick, X0 Y0
    If ( key )
        Send, %key%
}
