;=====================================================================
; Emacs keybinding
;   Last Changed: 19 Oct 2017
;=====================================================================

#NoEnv
#InstallKeybdHook
#UseHook
StringCaseSense, On

ENABLE_CMD_PROMPT := True

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
		clear_pre_x()
		clear_pre_spc()
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
	show_popup("C-x", "228822", "", 0, 200)
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
	if (A_IsSuspended) {
		bgcolor := ""
		font := "Caaaaaa Strike"
	} else {
		bgcolor := "222288"
		font := ""
	}
	show_popup("Emacs", bgcolor, font)
}

show_popup(label, bgcolor = "", font = "", timeout = 150, transparent = 250) {
	static WS_EX_TRANSPARENT = 0x20, WS_EX_NOACTIVATE = 0x8000000
	global popup_trans
	popup_trans := transparent
	hide_popup()
	if (bgcolor == "") {
		bgcolor := "222222"
	}
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
	popup_trans := popup_trans - 40
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
	enable_pre_x()
	Input in, B I M L1 T3, {F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}
	If ErrorLevel <> Timeout
	{
		If (Asc(in) <= 26) ; Ctrl+[a-z]
			in := "^" . Chr(Asc(in) + 0x60)
		If (in = "^c")
			kill_emacs()
		Else If (in = "^f")
			find_file()
		Else If (in = "k")
			kill_buffer()
		Else If (in = "^p")
			select_all()
		Else If (in = "^s")
			save_buffer()
		Else If (in = "u")
			undo()
		Else If (in = "w")
			change_window_size()
		Else If (in = "^w")
			write_file()
	}
	in :=
	Suspend,Off
	clear_pre_x()
	Return
;}

; send original key {
^!g::	Send ^g
^!q::	Send ^q
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
