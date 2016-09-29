@set src=BTPANConnect.ahk
@set dest=BTPANConnect.exe
@set icon=BTConnect.ico
@set resource1=BTDisconnect.ico,icongroup,250,0

del /q %dest% 2>NUL
ahk2exe /in %src% /out %dest% /icon %icon%
ResourceHacker -addoverwrite %dest%, %dest%, %resource1%
