; MButtonEmulate

#UseHook

*^RButton::
    ToolTip, Release <Ctrl> and Hold <R-Button>: <M-Button> drag`nHold <Ctrl> and Release <R-Button>: <M-Button> click
    while GetKeyState("Ctrl", "P") {
        If !GetKeyState("RButton", "P") {
            ToolTip
            Send, {Blind}{Click Middle}
            return
        }
        Sleep, 10
    }
    ToolTip
    Send, {Blind}{Click Middle Down}
    while GetKeyState("RButton", "P") {
        Sleep, 10
    }
    Send, {Blind}{Click Middle Up}
    return
