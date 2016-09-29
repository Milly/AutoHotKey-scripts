﻿;=====================================================================
; Bluetooth PAN Connect
;   Last Changed: 29 Sep 2016
;=====================================================================

; Usage -----------------------------------------{{{1
;
; ## インストール
;
; 1. AutoHotKey (1.1.*)をインストールする。(https://autohotkey.com/)
; 2. 任意のフォルダにこのスクリプトをコピーする。
; 3. PC とスマホを Bluetooth でペアリングする。
; 4. コントロールパネルの「デバイスとプリンター」を開く。
;    (3)で接続したスマホを選択し、右クリックメニューから「ショートカットの作成」を行う。
; 5. デスクトップに作成されたショートカットを(2)と同じフォルダに移動する。
;    移動したショートカットのファイル名を「BTLink」に変更する。
;
; ## 使用方法
;
; 1. スクリプトを実行する。
; 2. <Win>+Z キーを押下すると Bluetooth PAN 接続が切り替わる。
;
;
; Initialize -----------------------------------------{{{1

#NoEnv
SendMode Input
Menu Tray, NoMainWindow

BTPAN_LinkPath        := A_ScriptDir . "\BTLink.lnk"
BTPAN_Icon_Connect    := A_ScriptDir . "\BTConnect.ico"
BTPAN_Icon_Disconnect := A_ScriptDir . "\BTDisconnect.ico"
BTPAN_MenuLabel_Connect    := "接続方法(&C)"
BTPAN_MenuLabel_Disconnect := "デバイス ネットワークからの切断(&D)"

if (FileExist(BTPAN_LinkPath) == "") {
  MsgBox Please create Bluetooth Device Link.`n=> %BTPAN_LinkPath%
  ExitApp 1
}
BTPAN__updateTaskTray()


; Common Functions -----------------------------------------{{{1

ShellContextMenu(sPath, targetLabel="", nSubMenuPos=0)
{
  pIContextMenu := GetContextMenuObject(sPath)
  hMenu := DllCall("CreatePopupMenu", "Ptr")

  ;IContextMenu->QueryContextMenu
  DllCall(VTable(pIContextMenu, 3), "Ptr", pIContextMenu, "Ptr", hMenu, "UInt", 0, "UInt", 3, "UInt", 0x7FFF, "UInt", 0)

  if (targetLabel == "") {
    DllCall("GetCursorPos", "Int64*", pt)
    nID := DllCall("TrackPopupMenuEx", "Ptr", hMenu, "UInt", 0x0100|0x0001, "Int", pt << 32 >> 32, "Int", pt >> 32, "Ptr", A_ScriptHwnd, "UInt", 0)
  } else {
    nID := FindMenuCommand(hMenu, targetLabel, nSubMenuPos)
  }

  if (nID != 0) {
    InvokeMenuCommand(pIContextMenu, nID)
  }

  DllCall("DestroyMenu", "Ptr", hMenu)
  ObjRelease(pIContextMenu)
  return nID
}

GetContextMenuObject(sPath)
{
  hModule := DllCall("LoadLibrary", "Str", "shell32.dll", "Ptr")
  if sPath Is Not Integer
  {
    DllCall("shell32\SHParseDisplayName", "Str", sPath, "Ptr", 0, "Ptr*", pidl, "UInt", 0, "UInt*", 0)
  } else {
    DllCall("shell32\SHGetFolderLocation", "Ptr", 0, "Int", sPath, "Ptr", 0, "UInt", 0, "Ptr*", pidl)
  }
  DllCall("shell32\SHBindToParent", "Ptr", pidl, "Ptr", GUID4String(IID_IShellFolder,"{000214E6-0000-0000-C000-000000000046}"), "Ptr*", pIShellFolder, "Ptr*", pidlChild)
  ;IShellFolder->GetUIObjectOf
  DllCall(VTable(pIShellFolder, 10), "Ptr", pIShellFolder, "Ptr", 0, "UInt", 1, "Ptr*", pidlChild, "Ptr", GUID4String(IID_IContextMenu,"{000214E4-0000-0000-C000-000000000046}"), "Ptr", 0, "Ptr*", pIContextMenu)
  ObjRelease(pIShellFolder)
  CoTaskMemFree(pidl)
  DllCall("FreeLibrary", "UInt", hModule)
  return pIContextMenu
}

FindMenuCommand(hMenu, targetLabel, nSubMenuPos=0)
{
  MF_BYPOSITION := 0x0400
  nMaxLen := 100
  VarSetCapacity(sLabel, nMaxLen*2, 0)
  itemCount := DllCall("GetMenuItemCount", "Ptr", hMenu)
  loop %itemCount% {
    nPos := A_Index-1
    DllCall("GetMenuString", "Ptr", hMenu, "UInt", nPos, "Str", sLabel, "Int", nMaxLen, "UInt", MF_BYPOSITION)
    if (sLabel == targetLabel) {
      hSubMenu := DllCall("GetSubMenu", "Ptr", hMenu, "UInt", nPos, "Ptr")
      if (hSubMenu != 0) {
        return DllCall("GetMenuItemID", "Ptr", hSubMenu, "UInt", nSubMenuPos)
      }
      return DllCall("GetMenuItemID", "Ptr", hMenu, "UInt", nPos)
    }
  }
  return 0
}

InvokeMenuCommand(pIContextMenu, nID)
{
  /*
  typedef struct _CMINVOKECOMMANDINFOEX {
    DWORD   cbSize;         0
    DWORD   fMask;          4
    HWND    hwnd;           8
    LPCSTR  lpVerb;         8+1*A_PtrSize
    LPCSTR  lpParameters;   8+2*A_PtrSize
    LPCSTR  lpDirectory;    8+3*A_PtrSize
    int     nShow;          8+4*A_PtrSize
    DWORD   dwHotKey;       12+4*A_PtrSize
    HANDLE  hIcon;          16+4*A_PtrSize
    LPCSTR  lpTitle;        16+5*A_PtrSize
    LPCWSTR lpVerbW;        16+6*A_PtrSize
    LPCWSTR lpParametersW;  16+7*A_PtrSize
    LPCWSTR lpDirectoryW;   16+8*A_PtrSize
    LPCWSTR lpTitleW;       16+9*A_PtrSize
    POINT   ptInvoke;       16+10*A_PtrSize
  } CMINVOKECOMMANDINFOEX, *LPCMINVOKECOMMANDINFOEX;
  ; http://msdn.microsoft.com/en-us/library/bb773217%28v=VS.85%29.aspx
  */
  CMIC_MASK_UNICODE := 0x4000
  struct_size := 24+10*A_PtrSize
  VarSetCapacity(pici, struct_size, 0)
  NumPut(struct_size, pici, 0, "UInt")        ;cbSize
  NumPut(CMIC_MASK_UNICODE, pici, 4, "UInt")  ;fMask
  NumPut(A_ScriptHwnd, pici, 8, "UPtr")       ;hwnd
  NumPut(1, pici, 8+4*A_PtrSize, "UInt")      ;nShow
  NumPut(nID-3, pici, 8+1*A_PtrSize, "UPtr")  ;lpVerb
  NumPut(nID-3, pici, 16+6*A_PtrSize, "UPtr") ;lpVerbW

  ;IContextMenu->InvokeCommand
  DllCall(VTable(pIContextMenu, 4), "Ptr", pIContextMenu, "Ptr", &pici)
}

VTable(ppv, idx)
{
  return NumGet(NumGet(1 * ppv) + A_PtrSize * idx)
}

GUID4String(ByRef CLSID, String)
{
  VarSetCapacity(CLSID, 16, 0)
  return DllCall("ole32\CLSIDFromString", "WStr", String, "Ptr", &CLSID) >= 0 ? &CLSID : ""
}

CoTaskMemFree(pv)
{
  return DllCall("ole32\CoTaskMemFree", "Ptr", pv)
}

; Bluetooth PAN Functions -----------------------------------------{{{1

BTPAN__isConnected()
{
  psScript =
(
  $a = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "\"ServiceName=`'BthPan`'\"";
  exit [int]($a.IPAddress.Length -ne 0)
)
  RunWait powershell.exe -noprofile -command %psScript%, , hide
  return %ErrorLevel%
}

BTPAN__setConnection(connect)
{
  global BTPAN_LinkPath, BTPAN_MenuLabel_Connect, BTPAN_MenuLabel_Disconnect
  if (connect) {
    ShellContextMenu(BTPAN_LinkPath, BTPAN_MenuLabel_Connect, 0)
  } else {
    ShellContextMenu(BTPAN_LinkPath, BTPAN_MenuLabel_Disconnect)
  }
  BTPAN__updateTaskTray()
}

BTPAN__updateTaskTray()
{
  global BTPAN_Icon_Connect, BTPAN_Icon_Disconnect
  if (BTPAN__isConnected()) {
    icon := BTPAN_Icon_Connect
    state := "Connecting"
  } else {
    icon := BTPAN_Icon_Disconnect
    state := "Disconnect"
  }
  Menu Tray, Icon, %icon%
  Menu Tray, Tip, Bluetooth PAN`n%state%
}

BTPAN__connect()
{
  if (!BTPAN__isConnected()) {
    BTPAN__setConnection(True)
  }
}

BTPAN__disconnect()
{
  if (BTPAN__isConnected()) {
    BTPAN__setConnection(False)
  }
}

BTPAN__toggleConnection()
{
  BTPAN__setConnection(!BTPAN__isConnected())
}

; Hook Keys -----------------------------------------{{{1

#z:: BTPAN__toggleConnection()

; vim: set ts=2 sw=2 et fdm=marker fmr={{{,}}} :
