;=====================================================================
;  TrackWheel
;   $Revision: 130 $
;=====================================================================

; �����͒P�̗��p�A�܂���AutoExec���� #Include �őg�݂��񂾏ꍇ�ɒʂ�
TW_Init:
	If (A_LineFile == A_ScriptFullPath)
		Menu, Tray, Tip, TrackWheel
	TW_Initialize("TW.ini", true)
	return

;=====================================================================
; ���[�U��`�T�u���[�`���֘A
;=====================================================================
; ���[�U�A�N�V����
;   �w��T�u���[�`��������Ύ��s
;   �t���O�����[�U�ɂ��~�낳��Ă��邩�ǂ�����Ԃ�
TW_UserAction() {
	global
	TW_UserFlg:=true
	if IsLabel(TW_UserAction)
		Gosub, %TW_UserAction%
	return TW_UserFlg
}

;=====================================================================
; �z�b�g�L�[�֘A
;=====================================================================

; Ini�t�@�C���Őݒ肵���L�[���A"Hotkey"�R�}���h�ł��̃��x���Ɋ��蓖�Ă�
TW_HotkeyStart:
	if ((TW_Key:=TW_Start()) && (A_TimeSinceThisHotkey < TW__Timeout) && !(TW__QuitSendOnMove && TW_Scrolled))
		Send, {Blind}{%TW_Key%}
	return

;=====================================================================
; ���s����n
;=====================================================================

; �J�n�֐�
;  TW_State
;     0: �������Ȃ�
;     1: �}�E�X�ړ��}���J�n
;     2: �}�E�X�ړ����X�N���[���ɕϊ�
TW_Start(isToggle=false) {
	global TW_State, TW_RuleX, TW_RuleY, TW_Scrolled, TW_hHook, TW_ScrollCountX, TW_ScrollCountY
	Thread, NoTimers, True
	if !RegExMatch(A_ThisHotkey, "i)^[\^!\+#<>\*\$~]*(?:(?P<mod>\w+)\s+&\s+)*(?P<key>\w+)(?:\s+Up)*$", $)
		return
	If (TW_State==0) {
		TW_State:=1
		If (TW_SetUp() && TW_UserAction()) {
			TW_Scrolled:=0
			TW__%TW_RuleX%_Pre()
			TW__%TW_RuleY%_Pre()
			TW_GuiShow(true)
			TW_CursorHide(true)
			TW_State:=2
			if (isToggle)
				return
			KeyWait, % $mod
			KeyWait, % $key
			retvalue := $key
		}
	}
	TW_Stop()
	Thread, NoTimers, False
	return retvalue
}

TW_Stop() {
	global 
	If (TW_State) {
		TW_State:=0
		TW__%TW_RuleX%_Post()
		TW__%TW_RuleY%_Post()
		TW_CursorHide(false)
		TW_GuiShow(false)
		TW_TearDown()
	}
}

;=====================================================================
;  �}�E�X�t�b�N
;=====================================================================
; See:
;  http://msdn.microsoft.com/en-us/library/ms644970(VS.85).aspx
TW_MouseLL(nCode, wParam, lParam) {
	global TW_State, TW_X, TW_Y, TW__GuiHwnd, TW__DiffCount
	static counter:=0, dx:=0, dy:=0
	Critical
	SetBatchLines, -1
	if (nCode == 0 && TW_State>0) {
		if (wParam == 0x200) {
			if (TW_State==2) {
				dx += NumGet(lParam+0,0,"Int") - TW_X
				dy += NumGet(lParam+4,0,"Int") - TW_Y
				if (counter++>=TW__DiffCount) {
					PostMessage,A_EventInfo, dx, dy,,ahk_id %TW__GuiHwnd% ; A_EventInfo=RegisterCallback�̑�5����
					dx:=0, dy:=0, counter:=0
				}
			}
			return 1 ; �j��
		}
	}
	return DllCall("user32.dll\CallNextHookEx", "UInt",0, "Int",nCode, "UInt",wParam, "UInt",lParam)
}

;=====================================================================
; ���b�Z�[�W�҂��󂯊֐�
;=====================================================================
; �������g�ɓ�����ꂽ���b�Z�[�W����������Ƃ���
;   �����Ń��[�J���ϐ������Ă��
;   ���ꂪ�d���ď����d�؂�Ȃ��Ƃ��̌㑱�̃��b�Z�[�W��Drop���Ă�
;   �\��Ȃ��͂��Ȃ̂�Critical�ɂ͂��Ȃ�
TW_MsgListener(wParam, lParam, msg, hwnd) {
	global
	local dx,dy, ax, aY, lineX, lineY
	SetBatchLines, -1
	dx:=(wParam>0x7FFFFFFF) ? -(~wParam + 1) : wParam ; ����������
	dy:=(lParam>0x7FFFFFFF) ? -(~lParam + 1) : lParam
	aX:=Abs(dx), aY:=Abs(dy)
	if (TW__DenyBoth)
		if (aX > aY)
			dy := 0
		else
			dx := 0
	lineX:=TW_CalcLineX(dx), lineY:=TW_CalcLineY(dy)
	if (TW__Debug)
		Tooltip, `t X`t Y`t`nmove`t%dx%`t%dy%`nline`t%lineX%`t%lineY%`n`t%TW_ScrollCountX%`t%TW_ScrollCountY%
	if (lineX || lineY)
		TW_ScrollDispattcher(lineX, lineY, TW_RuleX, TW_RuleY)
		,TW_Scrolled:=true
}

TW_ScrollDispattcher(lineX, lineY, ruleX, ruleY) {
	global TW__SleepOnAlt, TW_ScrollCountX, TW_ScrollCountY
	keys:= GetKeyState("Shift")<<2 | GetKeyState("Ctrl")<<3
	
	if (keys && !(option & 0x100))
		ruleY := "Wheel",lineY:=(lineY>0) ? 1 : (lineY<0) ? -1 : 0
	
	If (ruleX = ruleY && IsFunc(func := "TW__" . ruleX)) {
		%func%(lineX, lineY)
		TW_ScrollCountX++
		TW_ScrollCountY++
	} else {
		if (lineX != 0) {
			TW__%ruleX%_X(lineX, keys)
			TW_ScrollCountX++
		} 
		if (lineY != 0) {
			TW__%ruleY%_Y(lineY, keys)
			TW_ScrollCountY++
		}
	}
	
	if (TW__SleepOnAlt > 0 && GetKeyState("Alt", "P"))
		Sleep, %TW__SleepOnAlt%
	
	TW_LastLine:=TW__Max(Abs(lineX), Abs(lineY))
}

; ���X�N���[���s�����v�Z�B�����͗L��
TW_CalcLineX(dx) {
	global TW_TX,TW_SX, TW_ReverseX, TW_Accel
	return TW_CalcLine(dx, TW_TX,TW_SX, TW_ReverseX, 0)
}

; �c�X�N���[���s�����v�Z�B�����͗L��
TW_CalcLineY(dy) {
	global TW_TY,TW_SY, TW_ReverseY, TW_Accel
	return TW_CalcLine(dy, TW_TY,TW_SY, TW_ReverseY, TW_Accel)
}

; �s���v�Z�̎��̊֐�
TW_CalcLine(dd, t, s, r, accel) {
	ab:=Abs(dd)
	value := accel ? Ceil(((ab-t)/s)**1.5) : Ceil((ab-t)/s)
	return (ab <= t) ? 0 
		: (dd>0 && !r) || (dd<0 && r) ? value : -value
}

;=====================================================================
; �X�N���[�����s�֐��Q
;=====================================================================

;==========================
; Wheel
;==========================
TW__Wheel_X(line, keys) {
	TW__Wheel_Common(0x20E, line, keys) ; WM_MOUSEHWHEEL
}
TW__Wheel_Y(line, keys) {
	TW__Wheel_Common(0x20A, line, keys) ; WM_MOUSEWHEEL
}
TW__Wheel_Common(msg, line, keys) {
	local notch
	notch := (TW_Accel && !(keys & 8)) ? 60 : 120 ; 120�̔{���ɂ��Ȃ��Ƃ��܂��Y�[�����Ȃ���������̂�
	SendMessage, msg, (-notch*line)<<16|keys, TW_lParam,,ahk_id %TW_HwndCtrl%
}

;==========================
; Scroll
;==========================
TW__Scroll_X(line) {
	local ret
	; WM_HSCROLL
	if (ret:=TW__Scroll_Common(0x114, line, TW_SbXType, TW_SbXHwnd, TW_SbXTarget, TW_SbOption)) && (TW_ScrollCountX==0) {
		TW_RuleX:="Scroll2", TW__Scroll2_X(line)
		If (TW__Debug)
			TrayTip, TrackWheel,  RuleX was changed from Scroll to Scroll2. [%ret%] / %TW_ScrollCountX%
	}
}
TW__Scroll_Y(line, keys) {
	local ret
	; WM_VSCROLL
	if (ret:=TW__Scroll_Common(0x115, line, TW_SbYType, TW_SbYHwnd, TW_SbYTarget, TW_SbOption)) {
		If (TW_ScrollCountY==0 && ret > 0) {
			TW_RuleY:="Scroll2", TW__Scroll2_Y(line)
			If (TW__Debug)
				TrayTip, TrackWheel,  RuleY was changed from Scroll to Scroll2. [%ret%] / %TW_ScrollCountY%
		} else {
			TW_ScrollCountY--
		}
	}
}
TW__Scroll_Common(msg, line, type, sbHwnd, target, option) {
	global TW_ScrollCountY
	if !TW_GetScrollInfoAll(sbHwnd ? sbHwnd : target, type, min, max, page, pos, trackPos)
		return 1 ; change scroll mode on failure of retrieving scrollinfo
	if (max>min && page<1) ; 1page�ʂ�0�ŕԂ����̂�������̂̑Ή�(eg. DF)
		page++
	max := (option & 0x02) ? 0xFFFF : max - page + 1
	,newPos := pos + line*Ceil(page/100)
	,newPos := (newPos>max) ? max : (newPos<min) ? min : newPos
	if (newPos == pos)
		return -1
	IfWinExist, ahk_id %target% ; using last found window
	{
		if (!(option & 0x01)) {
			TW_SetScrollInfoAll(sbHwnd ? sbHwnd : target, type, min, max, page, newPos, newPos)
			SendMessage, msg, 0x05 | newPos<<16, sbHwnd ; SB_THUMBTRACK
		}
		SendMessage, msg, 0x4 | newPos<<16, sbHwnd    ; SB_THUMBPOSITION
		SendMessage, msg, 0x8, sbHwnd                 ; SB_ENDSCROLL
		TW_GetScrollInfoAll(sbHwnd ? sbHwnd : target, type, min, max, page, accual, trackPos)
;		Tooltip, %pos% / %newPos% @%page%`n%min%/%max% / %accual%, 0, 0, 2
		If (accual==pos) && ((line>0 && pos<max-page) || (line<0 && pos>min))
			return 2 ; 
	}
	return 0
}

;==========================
; Scroll2
;==========================
TW__Scroll2_X(line) {
	global
	TW__Scroll2_Common(0x114, line, TW_SbXType, TW_SbXHwnd, TW_SbXTarget, TW_PX) ; WM_HSCROLL
}
TW__Scroll2_Y(line) {
	global
	TW__Scroll2_Common(0x115, line, TW_SbYType, TW_SbYHwnd, TW_SbYTarget, TW_PY) ; WM_VSCROLL
}

TW__Scroll2_Common(msg, line, type, sbHwnd, target , pm) {
	wParam := (line>0) ? (SB_LINEDOWN:=0x1) : (SB_LINEUP:=0x0)
	,count := Abs(line)
	if (count > pm)
		count := 1, wParam |= 2
	IfWinExist, ahk_id %target%
		Loop, %count%
			PostMessage, msg, wParam, sbHwnd
}

;==========================
; VKEY
;==========================
TW__Vkey_X(line) {
	global 
	TW__Vkey_Common(line < 0 ? 0x25 : 0x27, line, TW_SbXHwnd ? TW_SbXHwnd : TW_HwndCtrl) ; VK_LEFT / VK_RIGHT
}
TW__Vkey_Y(line) {
	global
	TW__Vkey_Common(line < 0 ? 0x26 : 0x28, line, TW_SbYHwnd ? TW_SbYHwnd : TW_HwndCtrl) ; VK_UP / VK_DOWN
}
; VKey�̏ꍇ�t�H�[�J�X���ړ����Ȃ��Ɩ����Ȃ��Ƃ�����̂Ŏ��{
TW__Vkey_Pre() {
	global
	ControlFocus,,ahk_id %TW_HwndCtrl%
}
TW__Vkey_Common(vk, line, ctrl) {
	PostMessage, 0x100, vk, 1,, ahk_id %ctrl% ; WM_KEYDOWN
	PostMessage, 0x101, vk, 1,, ahk_id %ctrl% ; WM_KEYUP
}

;==========================
; LView
;==========================
TW__LView_X(line) {
	TW__LView(line, 0)
}
TW__LView_Y(line) {
	TW__LView(0, line)
}
TW__LView(lineX, lineY) {
	global
	SendMessage, 0x1014, lineX*TW_LvLineX, lineY*TW_LvLineY,, ahk_id %TW_HwndCtrl% ; LVM_SCROLL(�h�b�g�P��)
}
; �O����
TW__LView_Pre() {
	local x1, y1, x2, y2, view
	TW_LvLineX := TW_LvLineY := 4
	WinGet, style, Style, ahk_id %TW_HwndCtrl%
	; LV_VIEW_ICON:=0, LV_VIEW_DETAILS:=1, LV_VIEW_SMALLICON:=2, LV_VIEW_LIST:=3, LV_VIEW_TILE:=4
	If (SendMessage(TW_HwndCtrl, 0x108f, 0, 0)==1 || style & 0x01 || style & 0x03) {  ; LVM_GETVIEW / LVS_LIST / LVS_REPORT
		If TW_LVM_GETITEMRECT(TW_HwndCtrl, 0, x1, y1, x2, y2, 2) ; LVIR_LABEL
			TW_LvLineY := y2-y1
		else
			TW_LvLineX := 12
	}
}

;==========================
; DragL
;==========================
TW__DragL_X(line) {
	TW__DragL(line, 0)
}
TW__DragL_Y(line) {
	TW__DragL(0, line)
}
TW__DragL(lineX, lineY) {
	local lParam
	lParam := (TW_X+lineX*4) | (TW_Y+lineY*4)<<16
	PostMessage, 0x201, 0, TW_lParam,, ahk_id %TW_HwndCtrl% ; WM_LBUTTONDOWN
	PostMessage, 0x200, 1, lParam   ,, ahk_id %TW_HwndCtrl% ; WM_MOUSEMOVE / 1:With LButton
	PostMessage, 0x202, 0, lParam   ,, ahk_id %TW_HwndCtrl% ; WM_LBUTTONUP
}

;==========================
; Task
;==========================
; X��Y�͋���
TW__Task_X(line) {
	TW__Task_Y(line)
}
TW__Task_Y(line) {
	If !GetKeyState("Alt") ; �_�������OK
		Send, {LAlt Down}
	If line>0
		Send, {Tab}
	Else
		Send, +{Tab}
	Sleep, 50
}
TW__Task_Post() {
	If GetKeyState("Alt")
		Send, {LAlt Up}
}

;==========================
; Trans
;==========================
; X��Y�͋���
TW__Trans_X(line) {
	TW__Trans_Y(line)
}
TW__Trans_Y(line) {
	local trans
	IfWinNotExist, ahk_id %TW_HwndWin%
		return
	WinGet, trans, Transparent
	if (trans == "")
		trans := 255
	trans -= line
	trans := (trans > 255) ? "OFF" : (trans < 1) ? 1 : trans
	WinSet, Trans, %trans%
	WinGet, trans, Transparent
	Tooltip, % "Trans : " (trans!="" ? trans : "OFF"),,,19
}
TW__Trans_Post() {
	Tooltip,,,,19
}

;=====================================================================
; �X�N���[�������n
;=====================================================================

; ����������
;   �X�N���[�����@�̌���͂����ōs��
TW_SetUp() {
	global 
	local RuleX,RuleY,str,SbState,style, w,h,h2,view, hitCode, LvState, $, $1, $2
	SetBatchLines,-1
	
	CoordMode, Mouse, Screen
	MouseGetPos, TW_X, TW_Y, TW_HwndWin, TW_HwndCtrl, 3
	TW_lParam := (TW_X < 0 ? TW_X + 0x10000 : TW_X) | (TW_Y < 0 ? TW_Y + 0x10000 : TW_Y)<<16 ; lParam�͌�ɍė��p
	
	If (TW_HwndCtrl) {
		SendMessage, 0x84, 0, TW_lParam,, ahk_id %TW_HwndCtrl% ; WM_NCHITTEST
		If (ErrorLevel = "FAIL")
			return false
		else if (ErrorLevel==0xffffffff) ; �����L���� -1
			MouseGetPos,,,,TW_HwndCtrl,2
	}
	
	TW_BypassCheck(TW_HwndCtrl, TW_HwndWin, TW_ClassCtrl, TW_ClassWin)
	SetFormat,Integer,D
	if (!TW_ClassCtrl)
		TW_ClassCtrl := TW_CreatePseudoClass(SendMessage(TW_HwndWin, 0x84, 0, TW_lParam))
	
	WinGet, style, Style, ahk_id %TW_HwndCtrl%
	
	; �ʃ��[���Ăяo��
	TW_LoadRule(TW_ClassWin, TW_ClassCtrl, RuleX, RuleY, TW_Option)
	
	TW_ParseOption(TW__$Option, TW_Accel, TW_SbOption) ; �f�t�H�ǂ�
	TW_ParseOption(TW_Option, TW_Accel, TW_SbOption)   ; �ʏ㏑��
	
	TW_ReverseX:=false,TW_ReverseY:=false
	If RegExMatch(RuleX, "^~(.+)$", $)
		RuleX:=$1, TW_ReverseX:=true
	If RegExMatch(RuleY, "^~(.+)$", $)
		RuleY:=$1, TW_ReverseY:=true
	
	if (TW_HwndCtrl)
		if !InStr(TW_ClassCtrl, "Mozzila") ; MDI�q����������A�N�e�B�u�������݂�
			TW_MdiActivate(TW_HwndWin, TW_HwndCtrl)
	
	; �R���g���[�����Ȃ�(Java�Ƃ�)�ꍇ�̓E�B���h�E�n���h���Ƃ���
	if (!TW_HwndCtrl)
		TW_HwndCtrl := TW_HwndWin
	
	LvState := TW_IsListView(TW_HwndCtrl)
	SbState := TW_FindScrollBar(TW_X, TW_Y, TW_HwndCtrl)
	
	TW_RuleX := TW_DefineRule(RuleX, TW__$RuleX, LvState, SbState & 1)
	TW_RuleY := TW_DefineRule(RuleY, TW__$RuleY, LvState, SbState & 2)
	
	if (TW__Debug)
		TW_ShowDebug()
	TW_ScrollCountX:=0, TW_ScrollCountY:=0
	return (TW_HwndWin>0)
}

TW_ParseOption(Byref option, ByRef accel, ByRef scroll) {
	afi := A_FormatInteger
	SetFormat, Integer, Hex
	Loop, PARSE, option, %A_Tab%%A_Space%, %A_Tab%%A_Space%
		If (A_LoopField="")
			continue
		else if RegExMatch(A_LoopField, "i)^(0x[a-f0-9]+|[0-9]+)$", $)
			scroll := $1
		else if RegExMatch(A_LoopField, "i)^a(0x[a-f0-9]+|[0-9]+)$", $)
			accel := $1
		else if RegExMatch(A_LoopField, "i)^s(0x[a-f0-9]+|[0-9]+)$", $)
			scroll := $1
	SetFormat, Integer, %afi%
}

; (�d�v) �X�N���[�������̌���
;   �D��x: �ʐݒ� > �f�t�H���g�ݒ� > ���X�g�r���[���� > �X�N���[���o�[���� > �z�C�[��
TW_DefineRule(iniRule, defRule, isListView, SbState) {
	global TW__DefaultS2
	return iniRule ? iniRule                                ; Ini�t�@�C���ɂ��郋�[��
		: defRule ? defRule                                   ; Ini��̃f�t�H���g���[��
		: (isListView) ? "LView"                              ; ���X�g�r���[����
		: SbState ? (TW__DefaultS2  ? "Scroll2" : "Scroll")   ; �X�N���[���o�[����
		: "Wheel"                                             ; �z�C�[��
}

TW_CreatePseudoClass(code) {
	return ((code ==  0) ? "$_NoWhere"      ; HTNOWHERE     ; �f�X�N�g�b�v��ɂ���
;			 : (code ==  1) ?  "$_Client"       ; HTCLIENT      ; �N���C�A���g�̈���ɂ���
			 : (code ==  2) ?  "$_Caption"      ; HTCAPTION     ; �L���v�V�����o�[��ɂ���
			 : (code ==  3) ?  "$_SysMenu"      ; HTSYSMENU     ; �V�X�e�����j���[���ɂ���
			 : (code ==  4) ?  "$_Size"         ; HTSIZE        ; �T�C�Y�{�b�N�X���ɂ���
			 : (code ==  5) ?  "$_Menu"         ; HTMENU        ; ���j���[�o�[���ɂ���
			 : (code ==  6) ?  "$_HScrool"      ; HTHSCROOL     ; �����X�N���[���o�[���ɂ���
			 : (code ==  7) ?  "$_VScroll"      ; HTVSCROLL     ; �����X�N���[���o�[���ɂ���
			 : (code ==  8) ?  "$_MinButton"    ; HTMINBUTTON   ; �A�C�R�����{�^����ɂ���
			 : (code ==  9) ?  "$_MaxButton"    ; HTMAXBUTTON   ; �ő剻�{�^����ɂ���
			 : (code == 10) ?  "$_Border"       ; HTLEFT        ; �Ϙg�̍��Ӌ��E����ɂ���
			 : (code == 11) ?  "$_Border"       ; HTRIGHT       ; �Ϙg�̉E�Ӌ��E����ɂ���
			 : (code == 12) ?  "$_Border"       ; HTTOP         ; �Ϙg�̏�Ӌ��E����ɂ���
			 : (code == 13) ?  "$_Border"       ; HTTOPLEFT     ; �Ϙg�̍�����ɂ���
			 : (code == 14) ?  "$_Border"       ; HTTOPRIGHT    ; �Ϙg�̉E����ɂ���
			 : (code == 15) ?  "$_Border"       ; HTBOTTOM      ; �Ϙg�̉��Ӌ��E����ɂ���
			 : (code == 16) ?  "$_Border"       ; HTBOTTOMLEFT  ; ���A�������ɂ���
			 : (code == 17) ?  "$_Border"       ; HTBOTTOMRIGHT ; ���A�E�����ɂ���
			 : (code == 18) ?  "$_Border"       ; HTBORDER      ; �Ϙg�������Ȃ����E����ɂ���
			 : (code == 20) ?  "$_CloseButton"  ; HTCLOSEBUTTON ; �����X�N���[���o�[���ɂ���
			 : "")
}

; �o�C�p�X�̃`�F�b�N�A���v������Q�Ƃ�ς���
TW_BypassCheck(ByRef hCtrl, ByRef hWindow, ByRef cCtrl, ByRef cWindow) {
	global TW__Bypass,TW_Bypassed
	SetFormat, Integer, H
	WinGetClass, cWindow, ahk_id %hWindow%
	TW_Bypassed=
	Loop, 100 {
		WinGetClass, cCtrl, ahk_id %hCtrl%
		if (!(TW__Bypass && RegExMatch(cCtrl, TW__Bypass)))
			break
		hParent := DllCall("GetParent", "UInt",hCtrl)
		if (hParent == 0 || hParent == hWindow)
			break
		hCtrl := hParent
		TW_Bypassed .= (TW_Bypassed ? "`n " : "") . cCtrl
	}
}

; �f�o�b�O�\���p
TW_ShowDebug() {
	global
	local str,revH,revV
	revH := TW_ReverseX ? "~" : "", revV := TW_ReverseY ? "~" : ""
	str =
(
[Window]
 %TW_HwndWin%	%TW_ClassWin%
[Control]
 %TW_HwndCtrl%	%TW_ClassCtrl%
[Bypass]
 %TW_Bypassed%
[Mode]
Horz	%TW_RuleX%	%revH%	(%TW_SbXHwnd%)
Vert	%TW_RuleY%	%revV%	(%TW_SbYHwnd%)
[Value]
SX,SY	%TW_SX%`t%TW_SX%
TX,TY	%TW_TX%`t%TW_TY%
PX,PY	%TW_PX%`t%TW_PY%
)
		TrayTip, TrackWheel, %str%, 10,17
}

; �㏈���p�֐��B�\�񂵂Ă邾�����Ċ����B
TW_TearDown() {
	global
	Tooltip
	return true
}

; ��������Ƀ��[�h�����ݒ�t�@�C�����O���O���񂵂ă}�b�`���O
TW_LoadRule(classWin, classCtrl, ByRef RuleX, ByRef RuleY, ByRef Option) {
	global TW__RuleTable, TW_SX,TW_SY,TW_TX,TW_TY,TW_PX,TW_PY
		,TW__$SX,TW__$SY,TW__$TX,TW__$TY,TW__$PX,TW__$PY
	SetFormat, Integer, D
	Loop, PARSE, TW__RuleTable, `n
	{
		StringSplit, col, A_LoopField, `,, %A_Space%%A_Tab%
		if (TW_WildCardMatches(col1, classWin) && TW_WildCardMatches(col2, classCtrl)) {
			RuleX:=col3, RuleY:=col4, Option:=col5
			break
		}
		Loop, 11
			col%A_Index%=
	}
	names = Option|SX|SY|TX|TY|PX|PY
	Loop, PARSE, names, |
		idx:=A_Index+4, TW_%A_LoopField%:=(col%idx%) ? col%idx% : TW__$%A_LoopField%
}

; ���C���h�J�[�h�}�b�`���O�֐�
TW_WildCardMatches(pattern, value) {
	if (pattern == "")
		return (value=="")
	else if (RegExMatch(pattern, "^\*(.+)\*$", $))
		pattern := $1, mode := 2
	else if (InStr(pattern, "*") == StrLen(pattern))
		mode:=1, pattern := SubStr(pattern, 1, StrLen(pattern)-1)
	return (mode == 2) ? InStr(value, pattern) 
		: (mode == 1) ? (InStr(value, pattern) == 1) : (value = pattern)
}

; MDI�q���A�N�e�B�u��
;   �E�B���h�E�X�^�C��������MDI�q����������A�N�e�B�u�������݂�
;   �ꉞ�A��K�w��܂Ŗʓ|�����Ă��
TW_MdiActivate(hwnd, ctrl) {
	target := ctrl
	Loop, 2 { ;��i�K��܂Ō��Ă�邱�Ƃɂ���
		if (target == hwnd || !WinExist("ahk_id " . target))
			break
		WinGet, style, Style
		if (style & 0x40c00000) { ; WS_CHILD + WS_CAPTION
			SendMessage, 0x22, target, 0 ; WM_CHILDACTIVATE
			return ErrorLevel
		}
		WinGet, exStyle, ExStyle
		if (exStyle & 0x00000040) { ; WS_EX_MDICHILD
			SendMessage, 0x222, target, 0 ; WM_MDIACTIVATE
			return ErrorLevel
		}
		target := DllCall("GetParent", "UInt",target)
	}
}

;=====================================================================
; �������֘A
;=====================================================================

; ������
;   �R�[���o�b�N�֐��̓o�^�Ƃ��A�������b�Z�[�W�̐ݒ�Ƃ�
;   �e��ϐ��̏������Ƃ�
TW_Initialize(file="TW.ini", trayIcon=false) {
	global 
	local dir, msg, hHookProc
	; �t�b�N�v���V�[�W��������
	msg := DllCall("RegisterWindowMessage", "Str","TrackWheelCallbackMsg")
	hHookProc := RegisterCallback("TW_MouseLL", "", 3, msg) ; ��3�����̓t�b�N�v���V�[�W����A_EventInfo�Ŏ��o����
	TW_hHook:= DllCall("SetWindowsHookEx"
		, "Int",  0x0E                                  ; Mouse_LL
		, "UInt", hHookProc                             ; 
		, "UInt", DllCall("GetModuleHandle", "UInt",0)  ; 
		, "UInt", 0)                                    ; 0:Global
	OnMessage(msg, "TW_MsgListener", 1)
	; �ϐ�������
	dir := A_WorkingDir
	SetWorkingDir, % RegExReplace(A_LineFile, "\\[^\\]+$","")
	TW__DiffCount:=4
	TW_LoadFile(file)
	TW_SetDefault()
	TW_GuiInit()
	If (trayIcon)
		Menu, Tray, Icon, %TW__Icon%
	TW_State:=0
	SetWorkingDir, %dir%
}

TW_UnhookMouse(hHook) {
	return DllCall("UnhookWindowsHookEx", "UInt",hHook)
}


TW_IniRead(file, name, section="config") {
	IniRead, value, %file%, %section%, %name%
	return value != "ERROR" ? value : ""
}

; �ݒ�t�@�C���ǂݍ���
TW_LoadFile(file) {
	global
	local $,$1,$2, section, value
	TW__RuleTable := "", section:=""
	; [config] �Z�N�V�����ǂݍ���
	if (value:=TW_IniRead(file, "Hotkey"))
		Hotkey, %value%, TW_HotkeyStart, On
	TW__Timeout       := TW_IniRead(file, "Timeout")
	TW__Icon          := A_IsCompiled ? A_ScriptFullPath : TW_GetFullPath(TW_IniRead(file, "Icon"))
	TW__Debug         := TW_IniRead(file, "Debug")
	TW__NoHide        := TW_IniRead(file, "NoHide")
	TW__DenyBoth      := TW_IniRead(file, "DenyBoth") ? true : false
	TW__DefaultS2     := TW_IniRead(file, "DefaultS2")
	TW__SleepOnAlt    := Round(TW_IniRead(file, "SleepOnAlt"))
	TW__QuitSendOnMove:= TW_IniRead(file, "QuitSendOnMove")
	TW__Bypass        := TW_IniRead(file, "Bypass")
	Loop, READ, %file%
		if (RegExMatch(A_LoopReadLine, "^\s*;|^\s*$"))
			continue
		else if (RegExMatch(A_LoopReadLine, "^\[(\w+)\]", $))
			section := $1
		else if (section = "table")
			TW__RuleTable .= (TW__RuleTable ? "`n" : "") . A_LoopReadLine
}

; �ʏ�̃A�v���ݒ�Ɠ������@�Ń��[�h���āA�f�t�H���g�ϐ��փZ�b�g
; �w�肪�Ȃ���΂����Œl��ݒ肷��
TW_SetDefault() {
	global
	TW_LoadRule("$Default", "$Default", TW__$RuleX,TW__$RuleY,TW__$Option)
	,TW__$SX := TW_SX ? TW_SX : 10 ; X�����x�f�t�H���g
	,TW__$SY := TW_SY ? TW_SY : 10 ; Y�����x    �V
	,TW__$TX := TW_TX ? TW_TX : 10 ; X������臒l�f�t�H���g
	,TW__$TY := TW_TY ? TW_TY : 1  ; Y������臒l    �V
	,TW__$PX := TW_PX ? TW_PX : 8  ; X���y�[�W���[�h臒l�f�t�H���g
	,TW__$PY := TW_PY ? TW_PY : 8  ; Y���y�[�W���[�h臒l    �V
}

;=====================================================================
; GUI����ʕ\���֘A
;=====================================================================

; GUI������
;   �O�̂Ɠ����B
TW_GuiInit() {
	global TW__GuiNo, TW__GuiHwnd, TW__Icon
	TW__GuiNo := 0
	Loop, 99 {
		Gui, %A_Index%:+LastFoundExist
		if WinExist()
			continue
		TW__GuiNo:=A_Index
		break
	}
	Gui, %TW__GuiNo%:Default
	Gui, +LastFound -Border +ToolWindow +AlwaysOnTop -Caption +0x02000000 -0x0CC00000 +E0x00080020
	WinSet, TransColor, 000001
	GUi, Color, 000001, 000001
	Gui, Margin, 0, 0
	Gui, Add, Picture,x0 y0 w32 h32 AltSubmit
		, % FileExist(TW__Icon) ? TW__Icon : A_WinDir "\system32\main.cpl"
	Gui, Show, Hide w64 h64, % "TrackWheel"
	TW__GuiHwnd:=WinExist()
}

TW_GuiShow(show) {
	global TW__GuiNo, TW_X, TW_Y, TW_RuleY
	Gui, %TW__GuiNo%:Default
	Gui, +LastFound +AlwaysOnTop +0x02000000 -0x0CC00000 +E0x00080020
	WinSet, TransColor, 000001
	if (show) {
		Gui, Show, % "NA x" (TW_X-16) " y" (TW_Y-16)
	} else
		Gui, Hide
}

; ����Ώۂ̃X���b�h�ɃA�^�b�`���ă}�E�X�J�[�\���̔�\���E�\���𐧌䂷��
TW_CursorHide(hide) {
	global TW_HwndWin, TW__NoHide, TW_ClassWin
	static myThread, targetThread
	if (TW__NoHide)
		return true
	if (TW_ClassWin = "#32769") ; #32769�� crss.exe (SYSTEM���[�U) ��Popup
		return true
	if (hide) {
		if (targetThread)
			return
		myThread := DllCall("kernel32.dll\GetCurrentThreadId", "UInt")
		targetThread := DllCall("user32.dll\GetWindowThreadProcessId", "UInt",TW_HwndWin, "Uint",0, "UInt")
		if (myThread == targetThread)
			targetThread := 0 ; �������M�Ȃ�A�^�b�`����K�v�Ȃ�
		else if (!DllCall("user32.dll\AttachThreadInput", "UInt",myThread, "UInt",targetThread, "Int",-1))
			targetThread := 0
		Loop
			if (DllCall("user32.dll\ShowCursor", "Int",false, "Int") < 0)
				break
	} else {
		Loop
			if (DllCall("user32.dll\ShowCursor", "Int",true, "Int") >= 0)
				break
		if (targetThread && DllCall("user32.dll\AttachThreadInput", "UInt",myThread, "UInt",targetThread, "Int", 0))
			targetThread := 0
	}
	return true
}

;=====================================================================
; ���X�g�r���[�p�`�F�b�N
;=====================================================================
TW_IsListView(hwnd) {
	global TW_LvLineX, TW_LvLineY
	state:=SendMessage(hwnd, 0x1014, 0, 0) ; ; LVM_SCROLL�� (0,0) �������Ă݂�
	If (state="FAIL" || !state)
		return false
	return true
}

;=====================================================================
; �X�N���[���o�[�֘A
;=====================================================================

; WM_HSCROLL/WM_VSCROLL�ɔ������邩�ǂ����𒲂ׂ�ƂƂ��ɁA
; �X�N���[���o�[�̃E�B���h�E�n���h�����擾����B
; �X�N���[���o�[�������̔z���ɖ����ꍇ��K�w��(����)�̃X�N���[���o�[��T��
; <strike>�����ėp�I</strike> �� �����\���̂Ȃ�����...
; 
; �߂�l(�ȉ���OR�l)
; 	0 : �X�N���[���s��
; 	1 : �����X�N���[���\
; 	2 : �����X�N���[���\
TW_FindScrollBar(sX, sY, ctrl) {
	global TW_X, TW_Y, TW_HwndCtrl
	static SC_HSCROLL:=1,SC_VSCROLL:=2,SB_HORZ:=0,SB_VERT:=1,SB_CTL:=2
		,SBS_VERT:=0x01,SBS_HORZ:=0,WS_VSCROLL:=0x00200000,WS_HSCROLL:=0x00100000
	retValue:=0
	,TW_SCROLLBAR_H_Set(SB_HORZ, 0, ctrl) ; �ΏۃR���g���[���̏��ŏ�����
	,TW_SCROLLBAR_V_Set(SB_VERT, 0, ctrl)
	; �ΏۃR���g���[�����̂��X�N���[���ł��邩�ǂ������`�F�b�N
	retValue := TW_GetScrollInfoAll(ctrl, SB_HORZ) | TW_GetScrollInfoAll(ctrl, SB_VERT)<<1
	if (retValue)
		return retValue
	target := ctrl, hCount:=0,vCount:=0
	WinGetClass, class, ahk_id %target%
	WinGetPos, cX, cY, cW, cH, ahk_id %ctrl%
	Loop, 2 {
		WinGet, list, ControlList, ahk_id %target%
		Loop, PARSE, list, `n
		{
			ControlGet, sbHwnd,Hwnd,,%A_LoopField%,ahk_id %target%
			WinGet, style, Style, ahk_id %sbHwnd%
			WinGetPos, x,y,w,h, ahk_id %sbHwnd%
			if (InStr(A_LoopField, "ScrollBar")==1) {
				if (style & SBS_VERT) { ; SBS_VERT
					if (cX > x || cY > (y+h)) ; PowerPoint���y�C�����O�p
						continue
					if (!(retValue & 2))
							|| ((vY!=y)&&((y<sY)&&(vY<y))||((vY>sY)&&(vY>y)))   ;�㉺����
							|| ((vX!=x)&&((x>sX)&&(vX>x))||((vX<sX)&&(vX<x)))   ;���E����
						vX:=x,vY:=y,vW:=w,vH:=h ;,VShwnd:=sbHwnd
						,TW_SCROLLBAR_V_Set(SB_CTL, sbHwnd, DllCall("GetParent", "UInt", sbHwnd)), retValue |= 2
				} else {
					if ((y+h) < sY || (cX+cW)<x) ; PowerPoint�m�[�g��/���y�C�����O�p
						continue
					if (!(retValue & 1))
							|| ((hX!=x)&&((x<sX)&&(hX<x))||((hX>sX)&&(hX>x)))      ;���E(Excel�^)
							|| ((hY!=y)&&((y+h>sY)&&(hY>y))||((hY+hH<sY)&&(hY<y))) ;�㉺(Word�^)
						hX:=x,hY:=y,hW:=w,hH:=h ;, HShwnd:=sbHwnd
						,TW_SCROLLBAR_H_Set(SB_CTL, sbHwnd, DllCall("GetParent", "UInt", sbHwnd)), retValue |= 1
				}
			} else if (InStr(A_LoopField, "CScrollBar")==1) { ; �ق� Access2002�p�A���Ȃ�蔲��
				if (style & WS_HSCROLL) && !(retValue & 0x1) ; �ŏ��Ɍ����������v�f
					TW_SCROLLBAR_H_Set(SB_HORZ, 0, sbHwnd), retValue |= 1
				if (style & WS_VSCROLL) && !(retValue & 0x2) ; �ŏ��Ɍ��������c�v�f
					TW_SCROLLBAR_V_Set(SB_VERT, 0, sbHwnd), retValue |= 2
			} else if (InStr(A_LoopField, "TScrollBox")==1) { ; Jane �� Viewer����)
				TW_SCROLLBAR_H_Set(SB_HORZ, 0, sbHwnd), retValue |= 1
				TW_SCROLLBAR_V_Set(SB_VERT, 0, sbHwnd), retValue |= 2
				break
			}
		}
		if (retValue)
			break
		target := DllCall("GetParent", "UInt",target, "UInt")
		if (target == 0)
			break
	}
	if (class = "HM32CLIENT" && !(vY<=sY && (vY+vH)>=sY ))
		PostMessage, 0x111, 142, 0,,ahk_id %ctrl%
	return retValue
}

; �ʓ|�Ȃ̂ł܂Ƃ߂ăZ�b�g����B
TW_SCROLLBAR_H_Set(type, sbHwnd, target) {
	global
	TW_SbXType:=type, TW_SbXHwnd:=sbHwnd, TW_SbXTarget:=target
}
TW_SCROLLBAR_V_Set(type, sbHwnd, target) {
	global
	TW_SbYType:=type, TW_SbYHwnd:=sbHwnd, TW_SbYTarget:=target
}

; �X�N���[���o�[�̏��𓾂�
TW_GetScrollInfoAll(hwnd, type, ByRef nMin=0, ByRef nMax=0, ByRef nPage=0, ByRef nPos=0, ByRef nTrackPos=0) {
	size:=VarSetCapacity(SCROLLINFO, 28, 0x00)
	NumPut(28,   SCROLLINFO, 0, "Int")
	,NumPut(0x17, SCROLLINFO, 4, "Int") ; SIF_RANGE(0x01) or SIF_PAGE(0x02) or SIF_POS(0x04) or SIF_TRACKPOS(0x10) = 0x17
	if (!DllCall("user32.dll\GetScrollInfo", "UInt",hwnd, "Int",type, "Int",&SCROLLINFO, "Int"))
		return false
	nMin := NumGet(SCROLLINFO, 8, "Int"), nMax := NumGet(SCROLLINFO, 12, "Int")
	, nPage := NumGet(SCROLLINFO, 16, "Int"), nPos := NumGet(SCROLLINFO, 20, "Int")
	, nTrackPos := NumGet(SCROLLINFO, 24, "Int")
	return true
}

; �X�N���[���o�[�����X�V����
TW_SetScrollInfoAll(hwnd, type, nMin, nMax,nPage,nPos,nTrackPos) {
	size:=VarSetCapacity(SCROLLINFO, 28, 0x00)
	,NumPut(size,     SCROLLINFO, 0, "Int")
	,NumPut(0x14,     SCROLLINFO, 4, "Int") ; SIF_POS or SIF_TRACKPOS
	,NumPut(nMin,     SCROLLINFO, 8, "Int")
	,NumPut(nMax,     SCROLLINFO, 12, "Int")
	,NumPut(nPage,    SCROLLINFO, 16, "Int")
	,NumPut(nPos,     SCROLLINFO, 20, "Int")
	,NumPut(nTrackPos SCROLLINFO, 24, "Int")
	return DllCall("user32.dll\SetScrollInfo", "UInt",hwnd, "Int",type, "UInt",&SCROLLINFO, "Int",true)
}

SendMessage(hwnd, msg, wParam, lParam) {
	SendMessage, msg, wParam, lParam,, ahk_id %hwnd%
	return ErrorLevel
}
TW__Max(a,b) {
	return (a>b) ? a : b
}
; �J�����g�f�B���N�g�����l�������w��̃p�X���A�h���C�u���[�g����̃t���p�X�ɕϊ�����
TW_GetFullPath(path) {
	VarSetCapacity(dest,512,0x00)
	dir:=A_WorkingDir
	DllCall("shlwapi.dll\PathCombine", "Str",dest, "Str",dir, "Str",path)
	return dest
}

; hwnd�Ŏw�肵�����X�g�r���[���̃A�C�e���̋�`�𓾂�B(�ڍו\���ł̃X�N���[���ʎZ�o�ŗ��p)
; �ǂ̋�`�𓾂邩�͈ȉ�����I��
;	 LVIR_BOUNDS   := 0x00,  LVIR_ICON        := 0x01
;	 LVIR_LABEL    := 0x02,  LVIR_SELECTBOUNDS:= 0x03
TW_LVM_GETITEMRECT(hwnd, idx, ByRef x1, ByRef y1, ByRef x2, ByRef y2, type=0) {
	size:=VarSetCapacity(rect, 16, 0), NumPut(type, rect, 0, "Int")
	WinGet, pid, PID, ahk_id %hwnd%
	If (hProcess:=DllCall("OpenProcess", "UInt",0x38, "Int", false, "UInt",pid)) ; PROCESS_VM_OPERATION(0x08)| PROCESS_VM_READ(0x10) | PROCESS_VM_WRITE(0x20)
		If (remote_buffer:=DllCall("VirtualAllocEx", "UInt",hProcess, "UInt",0, "UInt",0x1000, "UInt",0x1000, "UInt",0x4)) ; MEM_COMMIT / PAGE_READWRITE
			If DllCall("WriteProcessMemory", "UInt",hProcess, "UInt",remote_buffer, "UInt",&rect, "UInt",size, "UInt",0)
				If SendMessage(hwnd, 0x100e, idx, remote_buffer) ; LVM_GETITEMRECT
					If DllCall("ReadProcessMemory", "UInt",hProcess, "UInt",remote_buffer, "UInt",&rect, "UInt",size, "UInt",0)
						x1:=NumGet(rect, 0, "Int"), y1:=NumGet(rect, 4, "Int"), x2:=NumGet(rect, 8, "Int"), y2:=NumGet(rect,12, "Int"), ret:=true
			DllCall("VirtualFreeEx", "UInt",hProcess, "UInt",remote_buffer, "UInt",0, "UInt",0x8000)
		DllCall("CloseHandle", "UInt",hProcess)
	return ret
}
