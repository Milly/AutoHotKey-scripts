;=====================================================================
; Bluetooth PAN Connect
;   Last Changed: 29 Sep 2016
;=====================================================================

; Initialize -----------------------------------------{{{1

#NoEnv
SendMode Input

BTPAN_LinkPath := A_ScriptDir . "\BTLink.lnk"
BTPAN_MenuLabel_Connect    := "接続方法(&C)"
BTPAN_MenuLabel_Disconnect := "デバイス ネットワークからの切断(&D)"

if (FileExist(BTPAN_LinkPath) == "") {
  MsgBox Please create Bluetooth Device Link.`n=> %BTPAN_LinkPath%
  ExitApp 1
}

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
    nID := 0
    itemCount := DllCall("GetMenuItemCount", "Ptr", hMenu)
    loop %itemCount% {
      nPos := A_Index-1
      nLen := DllCall("GetMenuString", "Ptr", hMenu, "UInt", nPos, "Ptr", 0, "Int", 0, "UInt", 0x0400)  ;MF_BYPOSITION
      VarSetCapacity(sLabel, nLen*2+2, 0)
      DllCall("GetMenuString", "Ptr", hMenu, "UInt", nPos, "Str", sLabel, "Int", nLen+1, "UInt", 0x0400)
      if (sLabel == targetLabel) {
        hSubMenu := DllCall("GetSubMenu", "Ptr", hMenu, "UInt", nPos, "Ptr")
        if (hSubMenu != 0) {
          nID := DllCall("GetMenuItemID", "Ptr", hSubMenu, "UInt", nSubMenuPos)
        } else {
          nID := DllCall("GetMenuItemID", "Ptr", hMenu, "UInt", nPos)
        }
        break
      }
    }
  }

  if (nID != 0) {
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
    struct_size := 24+10*A_PtrSize
    VarSetCapacity(pici, struct_size, 0)
    NumPut(struct_size, pici, 0, "UInt")        ;cbSize
    NumPut(0x4000, pici, 4, "UInt")             ;fMask CMIC_MASK_UNICODE
    NumPut(A_ScriptHwnd, pici, 8, "UPtr")       ;hwnd
    NumPut(1, pici, 8+4*A_PtrSize, "UInt")      ;nShow
    NumPut(nID-3, pici, 8+1*A_PtrSize, "UPtr")  ;lpVerb
    NumPut(nID-3, pici, 16+6*A_PtrSize, "UPtr") ;lpVerbW

    ;IContextMenu->InvokeCommand
    DllCall(VTable(pIContextMenu, 4), "Ptr", pIContextMenu, "Ptr", &pici)
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

; vim: set ts=2 sw=2 noet fdm=marker fmr={{{,}}} :
