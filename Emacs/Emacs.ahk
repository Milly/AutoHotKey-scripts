;=====================================================================
; Emacs keybinding
;   Last Changed: 26 Jul 2013
;=====================================================================

#InstallKeybdHook
#UseHook

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
	SetTitleMatchMode,3
	IfWinActive,ahk_class ConsoleWindowClass ; Command Prompt, Cygwin
		Return False
	IfWinActive,ahk_class Vim   ; GVim
		Return False
	IfWinActive,ahk_class PuTTY ; Putty
		Return False
	IfWinActive,ahk_class VNCMDI_Window ; VNC
		Return False
	IfWinActive,ahk_class TscShellContainerClass ; Remote Desktop
		Return False
	Return True
}

is_cmd_prompt_active() {
	SetTitleMatchMode,3
	IfWinActive,ahk_class ConsoleWindowClass
	{
		SetTitleMatchMode,RegEx
		IfWinActive,Command Prompt|コマンド プロンプト|cmd\.exe
			Return True
	}
	Return False
}

update_icon() {
	local icon
	If A_IsSuspended
		icon := icon_disable
	Else If is_pre_x
		icon := icon_pre_x
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
if_pre_x(then_func, else_func = "") {
	global is_pre_x
	If is_pre_x
		%then_func%()
	Else If IsFunc(else_func)
		%else_func%()
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
find_file() {
	Send ^o
	clear_pre_x()
}
save_buffer() {
	Send, ^s
	clear_pre_x()
}
kill_emacs() {
	Send !{F4}
	clear_pre_x()
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
	clear_pre_x()
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
#k::
	Suspend,Permit
	confirm_exit()
	Return
;}

;}

#If is_target_window_active() ;{

; single commands {
^a::	move_beginning_of_line()
^b::	backward_char()
^c::	if_pre_x("kill_emacs")
^d::	delete_char()
^e::	move_end_of_line()
^f::	if_pre_x("find_file", "forward_char")
^g::	quit()
^h::	delete_backward_char()
^i::	indent_for_tab_command()
^j::	newline_and_indent()
^k::	kill_line()
^m::	newline()
^n::	next_line()
^o::	open_line()
^p::	if_pre_x("select_all", "previous_line")
^r::	isearch_backward()
^s::	if_pre_x("save_buffer", "isearch_forward")
^v::	scroll_down()
!v::	scroll_up()
^w::	kill_region()
!w::	kill_ring_save()
^x::	toggle_pre_x()
^y::	yank()
^/::	undo()
^@::	toggle_pre_spc()
^Space::	toggle_pre_spc()
;}

; toggle suspend {
^q::
	Suspend
	update_icon()
	Return
;}

;}

#If is_cmd_prompt_active() ;{

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
; vim: set ts=4 sw=4 noet fdm=marker fmr={,}:
