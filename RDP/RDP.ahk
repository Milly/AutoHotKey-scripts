;=====================================================================
; RDP keybinding
;   Last Changed: 11 Apr 2013
;=====================================================================

#InstallKeybdHook
#UseHook
#NoTrayIcon

; Send key functions {{{

copy_screen() ;{{{
{
    Send ^!{NumpadAdd}
} ;}}}
copy_window() ;{{{
{
    Send ^!{NumpadSub}
} ;}}}
open_start_menu() ;{{{
{
    Send {AltDown}{Home}
} ;}}}
open_window_menu() ;{{{
{
    Send {AltDown}{Del}
} ;}}}

; }}}

; Hook keys {{{

; Exit
^#k::
	MsgBox, 0x60124,, Exit RDP.ahk ?
	IfMsgBox, Yes
		ExitApp
	Return

#IfWinActive ahk_class TscShellContainerClass

^PrintScreen::	copy_screen()
^!PrintScreen::	copy_window()
^Space:: open_window_menu()

; }}}
