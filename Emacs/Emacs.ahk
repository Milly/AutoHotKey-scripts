;=====================================================================
; Emacs keybinding
;   Last Changed: 03 Sep 2018
;=====================================================================

#NoEnv
#InstallKeybdHook
#UseHook
StringCaseSense On
SetBatchLines -1


; Vars {

; Ini file
INI_FILE := A_ScriptDir . "\Emacs.ini"
INI_MAIN_SECTION := "Emacs"

; Options
ENABLE_CMD_PROMPT := True
THROW_INPUT_WITH_X := True
KILL_RING_MAX := 30
KILL_RING_STR_LEN := 20000
DISABLE_WINDOW_CLASSES
	:= DEFAULT_DISABLE_WINDOW_CLASSES
	:= "
(C LTrim Join,
	ConsoleWindowClass        ; Command Prompt, Cygwin
	ApplicationFrameWindow    ; UWP Application
)"
DISABLE_WINDOW_MATCHES := ""

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

; kill ring
kill_ring_last := 0
kill_ring_pos := 0
kill_ring_updating := False
kill_ring_types := []

; }

; IniFile object {

class IniFile {
	_file := ""

	__New(file) {
		this._file := file
	}

	__Get(section) {
		return this._getsection(section, False, -2)
	}

	_NewEnum() {
		return this.sections()._NewEnum()
	}

	HasKey(name) {
		return this.has_section(name)
	}

	sections() {
		file := this._file
		IniRead values, %file%
		res := Array()
		Loop Parse, values, `n, `r
			res.Push(A_LoopField)
		return res
	}

	options(section) {
		res := []
		for option, _ in this._option_items(section)
			res.Push(option)
		return res
	}

	_section_items() {
		res := Object()
		for _, section in this.sections()
			res[section] = this._getsection(section, False, -1)
		return res
	}

	_option_items(section) {
		if (!this.has_section(section))
			throw Exception("NoSection: " section, -2)
		file := this._file
		IniRead values, %file%, %section%
		res := Object()
		Loop Parse, values, `n, `r
		{
			StringSplit line, A_LoopField, =
			res[line1] := line2
		}
		return res
	}

	has_section(section) {
		sections := ",".join(this.sections())
		if section in %sections%
			return True
		return False
	}

	has_option(section, option) {
		default := "==NOT_A_VALUE_EXIST"
		value := this._getoption(section, option, default, -1)
		return (value != default)
	}

	items(section="") {
		if (section == "") {
			return this._section_items()
		}
		return this._option_items(section)
	}

	getsection(section, create=False) {
		return this._getsection(section, create, -2)
	}

	_getsection(section, create, what) {
		if (this.has_section(section) || create)
			return new IniProxy(this, section)
		throw Exception("NoSection: " section, what)
	}

	get(section, name, default="==NOT_A_VALUE") {
		return this._getoption(section, name, default, -2)
	}

	_getoption(section, name, default, what) {
		file := this._file
		IniRead value, %file%, %section%, %name%, %default%
		if (value == "==NOT_A_VALUE")
			throw Exception("NoOption in [" section "]: " name, what)
		return value
	}

	getbool(section, name, default:="==NOT_A_VALUE") {
		value := this._getoption(section, name, default, -2)
		if (value == default)
			return default
		if (value = "true" || value = "yes" || value = 1)
			return True
		if (value = "false" || value = "no" || value = 0)
			return False
		return default
	}
}

class IniProxy {
	_inifile := ""
	_section := ""

	__New(inifile, section) {
		this._inifile := inifile
		this._section := section
	}

	__Get(name) {
		return this._inifile._getoption(this._section, name, "==NOT_A_VALUE", -2)
	}

	__Call(name, args*) {
		inifile := this._inifile
		if (!IsFunc(ObjGetBase(this)[name]) && IsFunc(ObjGetBase(inifile)[name])) {
			try {
				return inifile[name](this._section, args*)
			} catch e {
				throw Exception(e.Message, -1, e.Extra)
			}
		}
	}

	_NewEnum() {
		return this.options()._NewEnum()
	}

	HasKey(name) {
		return this.has_option(name)
	}

	sections() {
		throw Exception("NotImplement: IniProxy.sections()", -1)
	}
}

; }

; String object {

String_Join(sep, obj) {
	static _join := "".base.join := Func("String_Join")
	out := ""
	for _, value in obj
		out .= value sep
	seplen := StrLen(sep)
	if (seplen > 0)
		out := SubStr(out, 1, -seplen)
	return out
}

; }

; Common functions {

check_active_window() {
	global
	last_active_id := active_id
	WinGet active_id, Id, A
	If (active_id != last_active_id)
	{
		clear_pre_x()
		clear_pre_spc()
	}
}

on_clipboard_change() {
	global
	if (kill_ring_updating)
		Return
	if (A_EventInfo == 0)  ; clipboard cleared
		Return
	if (StrLen(Clipboard) > KILL_RING_STR_LEN)
		Return
	if (++kill_ring_last > KILL_RING_MAX)
		kill_ring_last := 1
	kill_ring_types[kill_ring_last] := A_EventInfo
	; Array can not be used
	kill_ring_%kill_ring_last% := ClipboardAll
	kill_ring_pos := kill_ring_last
}

kill_ring_pop() {
	global
	if (kill_ring_pos == 0)
		Return
	if (--kill_ring_pos < 1)
		kill_ring_pos := KILL_RING_MAX
	if (StrLen(kill_ring_%kill_ring_pos%) == 0)
		kill_ring_pos := kill_ring_last
	kill_ring_updating := True
	Sleep 10 ;[ms]
	Clipboard := kill_ring_%kill_ring_pos%
	Sleep 10 ;[ms]
	kill_ring_updating := False
}

kill_ring_clear() {
	global
	kill_ring_pos := kill_ring_last := 0
	kill_ring_types := []
	Loop %KILL_RING_MAX%
		kill_ring_%A_Index% := ""
}

is_target_window_active() {
	local win_class
	WinGetClass win_class, A
	if win_class in %DISABLE_WINDOW_CLASSES%
	{
		Return False
	}
	if (StrLen(DISABLE_WINDOW_MATCHES) > 0)
	{
		if win_class contains %DISABLE_WINDOW_MATCHES%
		{
			Return False
		}
	}
	Return True
}

is_cmd_prompt_active() {
	IfWinActive ahk_class ConsoleWindowClass
	{
		IfWinActive ahk_exe cmd.exe
			Return True
		IfWinActive ahk_exe powershell.exe
			Return True
	}
	Return False
}

update_icon() {
	local icon
	if (is_pre_x)
		icon := ICON_PRE_X
	else if (A_IsSuspended)
		icon := ICON_DISABLE
	else if (is_target_window_active())
		icon := ICON_NORMAL
	else if (ENABLE_CMD_PROMPT && is_cmd_prompt_active())
		icon := ICON_NORMAL
	else
		icon := ICON_DISABLE
	Menu Tray, icon, %icon%,, 1
}

clear_pre_x() {
	global
	is_pre_x := False
	update_icon()
	SetTimer ShowPreXTimeout, Off
	hide_popup()
}

enable_pre_x() {
	global
	is_pre_x := True
	update_icon()
	SetTimer ShowPreXTimeout, -1000
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
	MsgBox 0x60124,, Exit Emacs.ahk ?
	IfMsgBox Yes
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
	Gui 1:Color, %bgcolor%
	Gui 1:Font, Cffffff S50 %font%
	Gui 1:Margin, 20, 20
	Gui 1:+LastFound +AlwaysOnTop +ToolWindow +Disabled -Border -Caption +E%WS_EX_TRANSPARENT% +E%WS_EX_NOACTIVATE%
	WinSet TransParent, %transparent%
	Gui 1:Add, Text, Center, %label%
	Gui 1:Show, NA Center AutoSize
	if (0 < timeout) {
		SetTimer PopupTimeout, % -timeout
	}
	Return

PopupTimeout:
	SetTimer PopupFadeOut, 20
	Return

PopupFadeOut:
	popup_trans -= 40
	if (popup_trans <= 0) {
		hide_popup()
	} else {
		Gui 1:+LastFound
		WinSet TransParent, %popup_trans%
	}
	Return
}

hide_popup() {
	SetTimer PopupTimeout, Off
	SetTimer PopupFadeOut, Off
	Gui 1:Destroy
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
yank_pop() {
	Send ^z
	kill_ring_pop()
	Send ^v
	clear_pre_spc()
}
yank_pop_dialog() {
	global kill_ring_last, kill_ring_pos, kill_ring_types
	if (kill_ring_pos == 0)
		Return
	kill_ring_pop()
	no := kill_ring_last - kill_ring_pos
	msg := "Kill-ring (" no "):"
	if (kill_ring_types[kill_ring_pos] == 1) {  ; text
		msg .= "`n" Clipboard
	} else {  ; non text
		msg .= " (non text)"
	}
	show_popup(msg, {bgcolor:"228822", font:"S16", timeout:1000, transparent:200}*)
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
	Send ^s
}
write_file() {
	Send !fa
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

pre_x() { ; Ctrl-x combination commands
	static CANCEL_KEYS := "
	(C LTrim Join
		{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}
		{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}
		{Capslock}{Numlock}{PrintScreen}{Pause}{Esc}
	)"
	global THROW_INPUT_WITH_X

	try {
		enable_pre_x()
		Suspend On
		Input key, B I M L1 T3, %CANCEL_KEYS%
		if (ErrorLevel = "Timeout")
			key := ""
		else if (ErrorLevel = "Max" && Asc(key) <= 26) ; Ctrl+[a-z]
			key := Chr(Asc(key) + 0x60)
		else if (SubStr(ErrorLevel, 1, 7) = "EndKey:")
			key := "{" . SubStr(ErrorLevel, 8) . "}"
		if (GetKeyState("Ctrl", "P"))
			key := "^" . key
		if (GetKeyState("Shift", "P"))
			key := "+" . key
		if (GetKeyState("Alt", "P"))
			key := "!" . key
	} finally {
		Suspend Off
		clear_pre_x()
	}

	if (key != "")
	{
		if (key = "^c")
			kill_emacs()
		else if (key = "^f")
			find_file()
		else if (key = "k")
			kill_buffer()
		else if (key = "^p")
			select_all()
		else if (key = "^s")
			save_buffer()
		else if (key = "u")
			undo()
		else if (key = "w")
			change_window_size()
		else if (key = "^w")
			write_file()
		else if (key = ":")
			kill_ring_clear()
		else if (THROW_INPUT_WITH_X)
		{
			if ("a" <= key && key <= "z")
				key := "^" . key
			Send %key%
		}
	}
}

; }

; Initialize {

initialize()
Return

initialize() {
	local ini, main, sect, disable_wins
	ini := new IniFile(INI_FILE)

	main := ini[INI_MAIN_SECTION]
	ENABLE_CMD_PROMPT := main.getbool("EnableCmdPrompt", ENABLE_CMD_PROMPT)
	THROW_INPUT_WITH_X := main.getbool("ThrowInputWithX", THROW_INPUT_WITH_X)
	KILL_RING_MAX := main.get("KillRingMax", KILL_RING_MAX)

	sect := INI_MAIN_SECTION ":DisableWindowClasses"
	disable_wins := ",".join(ini.getsection(sect, True).items())
	if (StrLen(disable_wins) > 0)
	{
		DISABLE_WINDOW_CLASSES := DEFAULT_DISABLE_WINDOW_CLASSES "," disable_wins
	}

	sect := INI_MAIN_SECTION ":DisableWindowClassMatches"
	DISABLE_WINDOW_MATCHES := ",".join(ini.getsection(sect, False).items())

	update_icon()
	SetTimer CheckActiveWindow, 500
}

; }

; Subroutines {

CheckActiveWindow:
	check_active_window()
	Return

OnClipboardChange:
	on_clipboard_change()
	Return

; }

; Hook keys {

; Global hook keys {

; Exit {
#^k::
	Suspend Permit
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
^x::	pre_x()
^y::	yank()
!y::	yank_pop_dialog()
^/::	undo()
^?::	redo()
^@::	toggle_pre_spc()
^_::	undo()
!<::	beginning_of_buffer()
!>::	end_of_buffer()
^Space::	toggle_pre_spc()
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
	show_suspend_popup()
	update_icon()
	Return
;}

;}

; }
; vim: set ts=4 sw=4 noet fdm=marker fmr={,} fml=2:
