; MButtonEmulate

#UseHook

^RButton::
    Click, Middle, Down
    while GetKeyState("RButton", "P")
    {
        continue
    }
    Click, Middle, Up
    return
