@setlocal enableextensions
@set src=BTPANConnect.ahk
@set dest=BTPANConnect.exe
@set icon=BTConnect.ico
@set resource1=BTDisconnect.ico,icongroup,250,0
@set archive=BTPANConnect.zip
@set files=^
  README.md ^
  ..\LICENSE.txt ^
  %dest%

:clean
del /q %dest% %archive% 2>NUL

:build_exe
ahk2exe /in %src% /out %dest% /icon %icon% || goto :eof
ResourceHacker -addoverwrite %dest%, %dest%, %resource1% || goto :eof

:archive
7z a -- %archive% %files% >NUL || goto :eof

