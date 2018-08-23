;=====================================================================
; Emacs keybinding
;   Last Changed: 23 Aug 2018
;=====================================================================

#NoEnv
#InstallKeybdHook
#UseHook
StringCaseSense On

; Vars {

; Ini file
INI_FILE := A_ScriptDir . "\Emacs.ini"
INI_MAIN_SECTION := "Emacs"

; Options
ENABLE_CMD_PROMPT := True
THROW_INPUT_WITH_X := True
KILL_RING_MAX := 30
DISABLE_WINDOW_CLASSES := DEFAULT_DISABLE_WINDOW_CLASSES := "ConsoleWindowClass"
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
kill_ring_pop := False
kill_ring := Object()

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
		Loop, Parse, values, `n, `r
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
		Loop, Parse, values, `n, `r
		{
			StringSplit, line, A_LoopField, =
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
	{
		out .= value sep
	}
	 return SubStr(out, 1, -1)
}

; }

; Common functions {

check_active_window() {
	global
	last_active_id := active_id
	WinGet active_id, Id, A
	If (active_id != last_active_id)
	{
		is_pre_x   := False
		is_pre_spc := False
		update_icon()
	}
}

on_clipboard_change() {
	global
	if (kill_ring_pop)
		Return
	if (A_EventInfo == 0)
		Return
	if (++kill_ring_last > KILL_RING_MAX)
		kill_ring_last := 1
	kill_ring_%kill_ring_last% := ClipboardAll
	kill_ring_pos := kill_ring_last
}

pop_kill_ring() {
	global
	if (kill_ring_pos == 0)
		Return
	if (--kill_ring_pos < 1)
		kill_ring_pos := KILL_RING_MAX
	if (StrLen(kill_ring_%kill_ring_pos%) == 0)
		kill_ring_pos := kill_ring_last
	kill_ring_pop := True
	Clipboard := kill_ring_%kill_ring_pos%
	Sleep 10 ;[ms]
	kill_ring_pop := False
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
	If is_pre_x
		icon := ICON_PRE_X
	Else If A_IsSuspended
		icon := ICON_DISABLE
	Else
		icon := ICON_NORMAL
	Menu Tray, icon, %icon%,, 1
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
	MsgBox 0x60124,, Exit Emacs.ahk ?
	IfMsgBox Yes
		ExitApp
}

show_suspend_popup() {
	static WS_EX_TRANSPARENT = 0x20, WS_EX_NOACTIVATE = 0x8000000
	global suspend_popup_trans
	suspend_popup_trans := 500
	Gui 1:Destroy
	if (A_IsSuspended) {
		Gui 1:Color, 222222
		Gui 1:Font, Caaaaaa S50 Strike
	} else {
		Gui 1:Color, 222288
		Gui 1:Font, Cffffff S50
	}
	Gui 1:Margin, 20, 20
	Gui 1:+LastFound +AlwaysOnTop +ToolWindow +Disabled -Border -Caption +E%WS_EX_TRANSPARENT% +E%WS_EX_NOACTIVATE%
	WinSet TransParent, 250
	Gui 1:Add, Text, Center, Emacs
	Gui 1:Show, NA Center AutoSize
	SetTimer SuspendPopupFadeOut, 20
	Return

SuspendPopupFadeOut:
	suspend_popup_trans := suspend_popup_trans - 40
	if (suspend_popup_trans <= 0) {
		SetTimer SuspendPopupFadeOut, Off
		Gui 1:Destroy
	} else if (suspend_popup_trans < 250) {
		Gui 1:+LastFound
		WinSet TransParent, %suspend_popup_trans%
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
yank_pop() {
	Send ^z
	pop_kill_ring()
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

pre_x() {
	static CANCEL_KEYS := String_Join(""
		, ["{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}"
		, "{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}"
		, "{Capslock}{Numlock}{PrintScreen}{Pause}{Esc}"])

	toggle_pre_x()
	try {
		Input key, B I M L1 T3, %CANCEL_KEYS%
		if (ErrorLevel = "Max" && Asc(key) <= 26) ; Ctrl+[a-z]
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
!y::	yank_pop()
^/::	undo()
^?::	redo()
^@::	toggle_pre_spc()
^_::	undo()
^Space::	toggle_pre_spc()
;}

; Ctrl-x combination commands {
^x::
	Suspend On
	pre_x()
	Suspend Off
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
