;=====================================================================
; IME auto off
;   Last Changed: 14 Jul 2012.
;=====================================================================

#NoTrayIcon
#InstallKeybdHook
#UseHook

; ターゲットウィンドウ
is_target()
{
    IfWinActive,ahk_class Vim ; GVim
    	Return 1
    IfWinActive,ahk_class PuTTY ; Putty
    	Return 1
    IfWinActive,ahk_class ConsoleWindowClass ; Cygwin
    	Return 1
}

; 半角/全角キー {vkF3sc029}
#If is_target()
Esc::Send,{vkF3sc029}{Esc}              ; Esc
^[::Send,{vkF3sc029}{CtrlDown}[{CtrlUp} ; Ctrl-[
^C::Send,{vkF3sc029}{CtrlDown}C{CtrlUp} ; Ctrl-C
