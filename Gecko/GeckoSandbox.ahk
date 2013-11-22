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
F11::   parent_focus("{F11}")

parent_focus(key) {
    ControlGetFocus, ctl
    StringGetPos, pos, ctl, GeckoFPSandboxChildWindow
    If ( pos = 0 )
        ControlClick, X1 Y1
    If ( key )
        Send, %key%
}
