;=====================================================================
; Emacs keybinding
;   Last Changed: 24 Jan 2018
;=====================================================================

#NoEnv
#InstallKeybdHook
#UseHook
StringCaseSense, On

ENABLE_CMD_PROMPT := True
THROW_INPUT_WITH_X := True

; Vars {

; Icons
icon_normal  := A_ScriptDir . "\Emacs-n.ico"
icon_disable := A_ScriptDir . "\Emacs-d.ico"
icon_pre_x   := A_ScriptDir . "\Emacs-x.ico"
active_id      := 0
last_active_id := 0

; Flag: C-x
is_pre_x   := False

; Flag: C-Space
is_pre_spc := False

; }

; Initialize {

update_icon()
SetTimer, CheckActiveWindow, 500
Return

CheckActiveWindow:
	check_active_window()
	Return

; }

; Common functions {

check_active_window() {
	global
	last_active_id := active_id
	WinGet, active_id, Id, A
	If (active_id != last_active_id)
	{
		is_pre_x   := False
		is_pre_spc := False
		update_icon()
	}
}

is_target_window_active() {
	; ConsoleWindowClass        = Command Prompt, Cygwin
	; TMobaXtermForm            = MobaXTerm
	; Vim                       = GVim
	; PuTTY                     = Putty
	; mintty                    = mintty
	; VirtualConsoleClass       = ConEmu
	; VNCMDI_Window             = VNC
	; TscShellContainerClass    = Remote Desktop
	; cygwin/x                  = Cygwin X
	local win_class, target_active := True
	WinGetClass, win_class, A
	if win_class in ConsoleWindowClass,TMobaXtermForm,PuTTY,mintty,VirtualConsoleClass,Vim,VNCMDI_Window,TscShellContainerClass
	{
		target_active := False
	}
	else if win_class contains cygwin/x
	{
		target_active := False
	}
	Return target_active
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
	If is_pre_x
		icon := icon_pre_x
	Else If A_IsSuspended
		icon := icon_disable
	Else
		icon := icon_normal
	Menu, Tray, icon, %icon%,, 1
}

clear_pre_x() {
	global
	is_pre_x := False
	update_icon()
}
toggle_pre_x() {
	global
	is_pre_x := ! is_pre_x
	update_icon()
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
	static WS_EX_TRANSPARENT = 0x20, WS_EX_NOACTIVATE = 0x8000000
	global suspend_popup_trans
	suspend_popup_trans := 500
	Gui, 1:Destroy
	if (A_IsSuspended) {
		Gui, 1:Color, 222222
		Gui, 1:Font, Caaaaaa S50 Strike
	} else {
		Gui, 1:Color, 222288
		Gui, 1:Font, Cffffff S50
	}
	Gui, 1:Margin, 20, 20
	Gui, 1:+LastFound +AlwaysOnTop +ToolWindow +Disabled -Border -Caption +E%WS_EX_TRANSPARENT% +E%WS_EX_NOACTIVATE%
	WinSet, TransParent, 250
	Gui, 1:Add, Text, Center, Emacs
	Gui, 1:Show, NA Center AutoSize
	SetTimer, SuspendPopupFadeOut, 20
	Return

SuspendPopupFadeOut:
	suspend_popup_trans := suspend_popup_trans - 40
	if (suspend_popup_trans <= 0) {
		SetTimer, SuspendPopupFadeOut, Off
		Gui, 1:Destroy
	} else if (suspend_popup_trans < 250) {
		Gui, 1:+LastFound
		WinSet, TransParent, %suspend_popup_trans%
	}
	Return
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
kill_line() {
	Send {ShiftDown}{END}{SHIFTUP}
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
^d::	delete_char()
^e::	move_end_of_line()
^f::	forward_char()
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
^Space::	toggle_pre_spc()
;}

; Ctrl-x combination commands {
^x::
	Suspend,On
	toggle_pre_x()
	endkeys = {F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}{Esc}
	Input key, B I M L1 T3, %endkeys%
	If (ErrorLevel = "Max" && Asc(key) <= 26) ; Ctrl+[a-z]
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
	toggle_pre_x()
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
