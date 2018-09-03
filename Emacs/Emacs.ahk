;=====================================================================
; Emacs keybinding
;   Last Changed: 01 Feb 2018
;=====================================================================

#NoEnv
#InstallKeybdHook
#UseHook
StringCaseSense, On
SetBatchLines, -1

; Vars {

; Ini file
INI_FILE := A_ScriptDir . "\Emacs.ini"
INI_DEFAULT_SECTION := "Emacs"

; Options
ENABLE_CMD_PROMPT := True
THROW_INPUT_WITH_X := True

; Icons
ICON_NORMAL  := A_ScriptDir . "\Emacs-n.ico"
ICON_DISABLE := A_ScriptDir . "\Emacs-d.ico"
ICON_PRE_X   := A_ScriptDir . "\Emacs-x.ico"

; Window id
active_id      := 0
last_active_id := 0

; Flag: C-x
is_pre_x   := False

; Flag: C-Space
is_pre_spc := False

; Windows classes to invalidate keybinding
INVALIDATE_TARGETS := "
(C LTrim Join,
	ConsoleWindowClass        ; Command Prompt, Cygwin
	TMobaXtermForm            ; MobaXTerm
	Vim                       ; GVim
	PuTTY                     ; Putty
	mintty                    ; mintty
	VirtualConsoleClass       ; ConEmu
	VNCMDI_Window             ; VNC
	TscShellContainerClass    ; Remote Desktop
)"

INVALIDATE_CONTAINS := "
(C LTrim Join,
	cygwin/x                  ; Cygwin X
)"

; }

; IniFile object {

IniFile := Object("_file", ""
	, "_section", ""
	, "__Get", "IniFile__Get"
	, "get", "IniFile_get"
	, "getbool", "IniFile_getbool")

IniFileOpen(file, section) {
	global IniFile
	self := Object("_file", file
		, "_section", section
		, "base", IniFile)
	return self
}

IniFile__Get(self, name) {
	value := self.get(name)
	if (value == "ERROR")
		throw "KeyError"
	return value
}

IniFile_get(self, name, default="ERROR") {
	file := self._file
	section := self._section
	IniRead, value, %file%, %section%, %name%, %default%
	return value
}

IniFile_getbool(self, name, default="ERROR") {
	value := self.get(name, default)
	if (value == default)
		return default
	if (value = "true" || value = "yes" || value = 1)
		return True
	if (value = "false" || value = "no" || value = 0)
		return False
	return default
}

; }

; Common functions {

check_active_window() {
	global
	last_active_id := active_id
	WinGet, active_id, Id, A
	if (active_id != last_active_id) {
		clear_pre_x()
		clear_pre_spc()
	}
}

is_target_window_active() {
	local win_class
	WinGetClass, win_class, A
	if win_class in %INVALIDATE_TARGETS%
		Return False
	if win_class contains %INVALIDATE_CONTAINS%
		Return False
	Return True
}

is_cmd_prompt_active() {
	IfWinActive,ahk_class ConsoleWindowClass
	{
		IfWinActive,ahk_exe cmd.exe
			Return True
		IfWinActive,ahk_exe powershell.exe
			Return True
	}
	Return False
}

update_icon() {
	local icon
	if (is_pre_x)
		icon := ICON_PRE_X
	else if (A_IsSuspended || !is_target_window_active())
		icon := ICON_DISABLE
	else
		icon := ICON_NORMAL
	Menu, Tray, icon, %icon%,, 1
}

clear_pre_x() {
	global
	is_pre_x := False
	update_icon()
	SetTimer, ShowPreXTimeout, Off
	hide_popup()
}

enable_pre_x() {
	global
	is_pre_x := True
	update_icon()
	SetTimer, ShowPreXTimeout, -1000
	Return

ShowPreXTimeout:
	show_popup("C-x", {bgcolor:"228822", timeout:0, transparent:200}*)
	Return
}

clear_pre_spc() {
	global
	is_pre_spc := False
}

toggle_pre_spc() {
	global
	is_pre_spc := ! is_pre_spc
}

confirm_exit() {
	MsgBox, 0x60124,, Exit Emacs.ahk ?
	IfMsgBox, Yes
		ExitApp
}

show_suspend_popup() {
	param := Object()
	if (A_IsSuspended) {
		param.font := "Caaaaaa Strike"
	} else {
		param.bgcolor := "222288"
	}
	show_popup("Emacs", param*)
}

show_popup(label, bgcolor = "222222", font = "", timeout = 150, transparent = 250) {
	static WS_EX_TRANSPARENT = 0x20, WS_EX_NOACTIVATE = 0x8000000
	global popup_trans
	popup_trans := transparent
	hide_popup()
	Gui, 1:Color, %bgcolor%
	Gui, 1:Font, Cffffff S50 %font%
	Gui, 1:Margin, 20, 20
	Gui, 1:+LastFound +AlwaysOnTop +ToolWindow +Disabled -Border -Caption +E%WS_EX_TRANSPARENT% +E%WS_EX_NOACTIVATE%
	WinSet, TransParent, %transparent%
	Gui, 1:Add, Text, Center, %label%
	Gui, 1:Show, NA Center AutoSize
	if (0 < timeout) {
		SetTimer, PopupTimeout, % -timeout
	}
	Return

PopupTimeout:
	SetTimer, PopupFadeOut, 20
	Return

PopupFadeOut:
	popup_trans -= 40
	if (popup_trans <= 0) {
		hide_popup()
	} else {
		Gui, 1:+LastFound
		WinSet, TransParent, %popup_trans%
	}
	Return
}

hide_popup() {
	SetTimer, PopupTimeout, Off
	SetTimer, PopupFadeOut, Off
	Gui, 1:Destroy
}

; }

; Send key functions {

delete_char() {
	Send {Del}
	clear_pre_spc()
}
delete_backward_char() {
	Send {BS}
	clear_pre_spc()
}
kill_word() {
	Send {ShiftDown}^{RIGHT}{ShiftUp}
	Sleep 10 ;[ms]
	Send ^x
	clear_pre_spc()
}
backward_kill_word() {
	Send {ShiftDown}^{LEFT}{ShiftUp}
	Sleep 10 ;[ms]
	Send ^x
	clear_pre_spc()
}
kill_line() {
	Send {ShiftDown}{END}{ShiftUp}
	Sleep 10 ;[ms]
	Send ^x
	clear_pre_spc()
}
open_line() {
	Send {END}{Enter}{Up}
	clear_pre_spc()
}
quit() {
	Send {ESC}
	clear_pre_spc()
}
newline() {
	Send {Enter}
	clear_pre_spc()
}
indent_for_tab_command() {
	Send {Tab}
	clear_pre_spc()
}
newline_and_indent() {
	Send {Enter}{Tab}
	clear_pre_spc()
}
isearch_forward() {
	Send ^f
	clear_pre_spc()
}
isearch_backward() {
	Send ^f
	clear_pre_spc()
}
kill_region() {
	Send ^x
	clear_pre_spc()
}
kill_ring_save() {
	Send ^c
	clear_pre_spc()
}
yank() {
	Send ^v
	clear_pre_spc()
}
undo() {
	Send ^z
	clear_pre_spc()
}
redo() {
	Send ^y
	clear_pre_spc()
}
find_file() {
	Send ^o
}
save_buffer() {
	Send, ^s
}
write_file() {
	Send, !fa
}
kill_emacs() {
	Send !{F4}
}
kill_buffer() {
	Send ^w
}
move_beginning_of_line() {
	global
	If is_pre_spc
		Send +{HOME}
	Else
		Send {HOME}
}
move_end_of_line() {
	global
	If is_pre_spc
		Send +{END}
	Else
		Send {END}
}
beginning_of_buffer() {
	global
	If is_pre_spc
		Send +^{HOME}
	Else
		Send ^{HOME}
}
end_of_buffer() {
	global
	If is_pre_spc
		Send +^{END}
	Else
		Send ^{END}
}
previous_line() {
	global
	If is_pre_spc
		Send +{Up}
	Else
		Send {Up}
}
next_line() {
	global
	If is_pre_spc
		Send +{Down}
	Else
		Send {Down}
}
forward_char() {
	global
	If is_pre_spc
		Send +{Right}
	Else
		Send {Right}
}
backward_char() {
	global
	If is_pre_spc
		Send +{Left}
	Else
		Send {Left}
}
forward_word() {
	global
	If is_pre_spc
		Send +^{Right}
	Else
		Send ^{Right}
}
backward_word() {
	global
	If is_pre_spc
		Send +^{Left}
	Else
		Send ^{Left}
}
scroll_up() {
	global
	If is_pre_spc
		Send +{PgUp}
	Else
		Send {PgUp}
}
scroll_down() {
	global
	If is_pre_spc
		Send +{PgDn}
	Else
		Send {PgDn}
}
select_all() {
	Send ^a
}
move_window_position() {
	Send !{Space}m
}
change_window_size() {
	Send !{Space}s
}

cmd_yank() {
	Send !{Space}ep
	clear_pre_spc()
}
cmd_search_forward() {
	Send !{Space}ef!d!n
	clear_pre_spc()
}
cmd_search_backward() {
	Send !{Space}ef!u!n
	clear_pre_spc()
}

; }

; Initialize {

initialize()
Return

initialize() {
	local ini
	ini := IniFileOpen(INI_FILE, INI_DEFAULT_SECTION)
	ENABLE_CMD_PROMPT := ini.getbool("EnableCmdPrompt", ENABLE_CMD_PROMPT)
	THROW_INPUT_WITH_X := ini.getbool("ThrowInputWithX", THROW_INPUT_WITH_X)

	update_icon()
	SetTimer, CheckActiveWindow, 500
}

; }

; Subroutines {

CheckActiveWindow:
	check_active_window()
	Return

; }

; Hook keys {

; Global hook keys {

; Exit {
#^k::
	Suspend,Permit
	confirm_exit()
	Return
;}

;}

#If is_target_window_active() ;{

; single commands {
^a::	move_beginning_of_line()
^b::	backward_char()
!b::	backward_word()
^d::	delete_char()
!d::	kill_word()
!BS::	backward_kill_word()
^e::	move_end_of_line()
^f::	forward_char()
!f::	forward_word()
^g::	quit()
^h::	delete_backward_char()
^i::	indent_for_tab_command()
^j::	newline_and_indent()
^k::	kill_line()
^m::	newline()
^n::	next_line()
^o::	open_line()
^p::	previous_line()
^r::	isearch_backward()
^s::	isearch_forward()
^v::	scroll_down()
!v::	scroll_up()
^w::	kill_region()
!w::	kill_ring_save()
^y::	yank()
^/::	undo()
^?::	redo()
^@::	toggle_pre_spc()
^_::	undo()
!<::	beginning_of_buffer()
!>::	end_of_buffer()
^Space::	toggle_pre_spc()
;}

; Ctrl-x combination commands {
^x::
	Suspend,On
	enable_pre_x()
	endkeys = {F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}{Esc}
	Input key, B I M L1 T3, %endkeys%
	If (ErrorLevel = "Timeout")
		key := ""
	Else If (ErrorLevel = "Max" && Asc(key) <= 26) ; Ctrl+[a-z]
		key := Chr(Asc(key) + 0x60)
	Else If (SubStr(ErrorLevel, 1, 7) = "EndKey:")
		key := "{" . SubStr(ErrorLevel, 8) . "}"
	If (GetKeyState("Ctrl", "P"))
		key := "^" . key
	If (GetKeyState("Shift", "P"))
		key := "+" . key
	If (GetKeyState("Alt", "P"))
		key := "!" . key
	If (key <> "")
	{
		If (key = "^c")
			kill_emacs()
		Else If (key = "^f")
			find_file()
		Else If (key = "k")
			kill_buffer()
		Else If (key = "^p")
			select_all()
		Else If (key = "^s")
			save_buffer()
		Else If (key = "u")
			undo()
		Else If (key = "w")
			change_window_size()
		Else If (key = "^w")
			write_file()
		Else If (THROW_INPUT_WITH_X)
		{
			If ("a" <= key && key <= "z")
				key := "^" . key
			Send %key%
		}
	}
	key :=
	Suspend,Off
	clear_pre_x()
	Return
;}

; toggle suspend {
^q::
	Suspend
	show_suspend_popup()
	update_icon()
	Return
;}

;}

#If ENABLE_CMD_PROMPT && is_cmd_prompt_active() ;{

; single commands {
^a::	move_beginning_of_line()
^b::	backward_char()
^d::	delete_char()
^e::	move_end_of_line()
^f::	forward_char()
^h::	delete_backward_char()
^m::	newline()
^n::	next_line()
^p::	previous_line()
^r::	cmd_search_backward()
^s::	cmd_search_forward()
^v::	scroll_down()
!v::	scroll_up()
^y::	cmd_yank()
;}

; toggle suspend {
^q::
	Suspend
	update_icon()
	Return
;}

;}

; }
; vim: set ts=4 sw=4 noet fdm=marker fmr={,} fml=2:
