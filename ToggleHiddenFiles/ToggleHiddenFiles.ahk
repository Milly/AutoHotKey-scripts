;=====================================================================
; Toggle Hidden Files
;   Last Changed: 29 Jul 2013.
;=====================================================================

#NoTrayIcon
#SingleInstance

; WINDOWS KEY + H TOGGLES HIDDEN FILES
#h::
    RegRead, HiddenFiles_Status, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden
    If HiddenFiles_Status = 2
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
    Else
	RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
    WinGetClass, eh_Class,A
    If (eh_Class = "#32770" OR A_OSVersion != "WIN_XP")
	send, {F5}
    Else
	PostMessage, 0x111, 28931,,, A
    Return
