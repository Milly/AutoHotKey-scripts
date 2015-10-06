; MButtonEmulate

#UseHook

^RButton::
    while GetKeyState("Ctrl", "P") {
        Sleep, 10
    }
    Send, {Click Middle Down}
    while GetKeyState("RButton", "P")
    {
        Sleep, 10
    }
    Send, {Click Middle Up}
    return
