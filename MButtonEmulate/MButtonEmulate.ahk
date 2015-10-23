; MButtonEmulate

#UseHook

^RButton::
    ToolTip, Release <Ctrl> and Hold <R-Button>: <M-Button> drag`nHold <Ctrl> and Release <R-Button>: <M-Button> click
    while GetKeyState("Ctrl", "P") {
        If !GetKeyState("RButton", "P") {
            ToolTip
            Send, {Click Middle}
            return
        }
        Sleep, 10
    }
    ToolTip
    Send, {Click Middle Down}
    while GetKeyState("RButton", "P") {
        Sleep, 10
    }
    Send, {Click Middle Up}
    return
