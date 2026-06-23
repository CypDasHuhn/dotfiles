#Requires AutoHotkey v2.0
#WinActivateForce

#!t:: {
    Run('wsl.exe --exec setsid feet',, 'Hide')
}

F4::{
    hwnd := FindWslgWindow()
    if !hwnd
        return

    WinActivate(hwnd)
    WinWaitActive(hwnd,, 1)
    Sleep 5

    CoordMode("Mouse", "Client")
    MouseClick("Left", 120, 140, 1, 0)
}

FindWslgWindow() {
    for hwnd in WinGetList("ahk_class RAIL_WINDOW ahk_exe msrdc.exe") {
        if WinGetMinMax(hwnd) != -1
            return hwnd
    }
    return 0
}
