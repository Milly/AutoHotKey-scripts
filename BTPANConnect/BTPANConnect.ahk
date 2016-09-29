;=====================================================================
; Bluetooth PAN Connect
;
; Author: Milly
; Last Changed: 30 Sep 2016
; Update: https://github.com/Milly/AutoHotKey-scripts/releases/
;=====================================================================

; Initialize -----------------------------------------{{{1

#NoEnv
#NoTrayIcon
SendMode Input
Menu Tray, NoMainWindow
Menu Tray, NoStandard

BTPAN_LinkPath        := A_ScriptDir . "\BTLink.lnk"
BTPAN_Icon_Connect    := A_ScriptDir . "\BTConnect.ico"
BTPAN_Icon_Disconnect := A_ScriptDir . "\BTDisconnect.ico"
BTPAN_IconResource_Connect    := -159
BTPAN_IconResource_Disconnect := -250
BTPAN_Tip_Connect     := "Bluetooth PAN アクセス"
BTPAN_Tip_Disconnect  := "Bluetooth PAN 未接続"
BTPAN_Menu_Connection := "Bluetooth PAN に接続(&C)"
BTPAN_Menu_Devices    := "デバイス一覧を表示(&O)"
BTPAN_Menu_Exit       := "終了(&X)"
BTPAN_CheckStatusInterval := 10000 ;msec

BTPAN_MenuLabel_Connect    := "接続方法(&C)"
BTPAN_MenuLabel_Disconnect := "デバイス ネットワークからの切断(&D)"
SHELL_DevicesAndPrinters := "::{A8A91A66-3A7D-4424-8D24-04E180695C7A}"

if (FileExist(BTPAN_LinkPath) == "") {
  Run explorer.exe "shell:%SHELL_DevicesAndPrinters%"
  MsgBox Please create Bluetooth Device Link.`n=> %BTPAN_LinkPath%
  ExitApp 1
}
BTPAN__checkStatus(True)
return


; Common Functions -----------------------------------------{{{1

ShellLinkResolveDisplayName(sPath, uFlag=0)
{
  static CLSID_ShellLink  := "{00021401-0000-0000-C000-000000000046}"
  static IID_IShellLinkW  := "{000214F9-0000-0000-C000-000000000046}"
  static IID_IPersistFile := "{0000010b-0000-0000-C000-000000000046}"
  static STGM_Read := 0x00000000
  static SLR_NO_UI := 0x0001

  pIShellLink := ComObjCreate(CLSID_ShellLink, IID_IShellLinkW)
  pIPersistFile := ComObjQuery(pIShellLink, IID_IPersistFile)
  try {
    if (hResult := DllCall("shell32\SHGetDesktopFolder", "Ptr*", pIShellFolder))
      return False
    ;IPersistFile->Load
    if (hResult := DllCall(VTable(pIPersistFile, 5), "Ptr", pIPersistFile, "Str", sPath, "UInt", STGM_Read))
      return False
    ;IShellLink->Resolve
    ; if (hResult := DllCall(VTable(pIShellLink, 19), "Ptr", pIShellLink, "Ptr", A_ScriptHwnd, "UInt", SLR_NO_UI))
    ;   return False
    ;IShellLink->GetIDList
    if (hResult := DllCall(VTable(pIShellLink, 4), "Ptr", pIShellLink, "Ptr*", pidl))
      return False
    return ShellGetDisplayNameOf(pIShellFolder, pidl, uFlag)
  } catch e {
    return False
  } finally {
    ObjRelease(pIShellFolder)
    ObjRelease(pIPersistFile)
    ObjRelease(pIShellLink)
    CoTaskMemFree(pidl)
  }
}


ShellGetDisplayNameOf(pIShellFolder, pidl, uFlag)
{
  VarSetCapacity(name, 264, 0)  ;STRRET
  ;IShellFolder->GetDisplayNameOf
  if (hResult := DllCall(VTable(pIShellFolder, 11), "Ptr", pIShellFolder, "Ptr", pidl, "UInt", uFlag, "Ptr", &name))
    return False
  if (hResult := DllCall("shlwapi\StrRetToStr", "Ptr", &name, "Ptr", pidl, "Ptr*", pName))
    return False
  try {
    return StrGet(pName, "UTF-16")
  } finally {
    CoTaskMemFree(pName)
  }
}


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
  if (pv)
    return DllCall("ole32\CoTaskMemFree", "Ptr", pv)
}


; Bluetooth PAN Functions -----------------------------------------{{{1

BTPAN__isConnected()
{
  wmiService := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
  adapters := wmiService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration")
  for adp in adapters
    if (adp.ServiceName == "BthPan")
      return adp.IPAddress.MaxIndex() != ""
  return False
}


BTPAN__setConnection(connect)
{
  global BTPAN_LinkPath, BTPAN_MenuLabel_Connect, BTPAN_MenuLabel_Disconnect
  if (connect) {
    ShellContextMenu(BTPAN_LinkPath, BTPAN_MenuLabel_Connect, 0)
  } else {
    ShellContextMenu(BTPAN_LinkPath, BTPAN_MenuLabel_Disconnect)
  }
  BTPAN__checkStatus()
}


BTPAN__checkStatus(forceUpdate=False)
{
  global BTPAN_lastConnectionStatus, BTPAN_CheckStatusInterval
  connected := BTPAN__isConnected()
  if (forceUpdate || BTPAN_lastConnectionStatus != connected) {
    BTPAN_lastConnectionStatus := connected
    if (connected) {
      SetTimer BTPAN__checkStatusCallback, %BTPAN_CheckStatusInterval%
    } else {
      SetTimer BTPAN__checkStatusCallback, Off
    }
    BTPAN__updateTaskTray()
  }
}

BTPAN__checkStatusCallback:
  BTPAN__checkStatus()
  return


BTPAN__updateTaskTray()
{
  local icon, iconResource, state, check, target
  if (BTPAN__isConnected()) {
    icon := BTPAN_Icon_Connect
    iconResource := BTPAN_IconResource_Connect
    state := BTPAN_Tip_Connect
    check := "Check"
    if (target := ShellLinkResolveDisplayName(BTPAN_LinkPath))
      target .= "`n"
  } else {
    icon := BTPAN_Icon_Disconnect
    iconResource := BTPAN_IconResource_Disconnect
    state := BTPAN_Tip_Disconnect
    check := "Uncheck"
    target := ""
  }
  if (A_IsCompiled) {
    Menu Tray, Icon, %A_ScriptFullPath%, %iconResource%
  } else {
    Menu Tray, Icon, %icon%
  }
  Menu Tray, Tip, %target%%state%
  Menu Tray, DeleteAll
  Menu Tray, Add, %BTPAN_Menu_Connection%, MENU_toggleConnection
  Menu Tray, %check%, %BTPAN_Menu_Connection%
  Menu Tray, Default, %BTPAN_Menu_Connection%
  Menu Tray, Add, %BTPAN_Menu_Devices%, MENU_openDevicesFolder
  Menu Tray, Add, %BTPAN_Menu_Exit%, MENU_exitApplication
  Menu Tray, Icon ;enable tray icon
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


; Menu Commands -----------------------------------------{{{1

MENU_toggleConnection:
  BTPAN__toggleConnection()
  return

MENU_openDevicesFolder:
  Run explorer.exe "shell:%SHELL_DevicesAndPrinters%"
  return

MENU_exitApplication:
  ExitApp 0


; Hook Keys -----------------------------------------{{{1

#z:: BTPAN__toggleConnection()


; vim: set ts=2 sw=2 et fdm=marker fmr={{{,}}} :
