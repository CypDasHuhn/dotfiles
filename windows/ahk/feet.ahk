#Requires AutoHotkey v2.0

#!t:: Run('wsl.exe --exec setsid feet',, 'Hide')

F4:: {
    hwnd := FindWslgWindow()
    if !hwnd
        return
    ForceFocusRail(hwnd)
}

FindWslgWindow() {
    fallback := 0
    for hwnd in WinGetList("ahk_class RAIL_WINDOW") {
        if WinGetMinMax(hwnd) = -1
            continue
        if !fallback
            fallback := hwnd
        title := WinGetTitle(hwnd)
        if InStr(title, "feet") || InStr(title, "foot")
            return hwnd
    }
    return fallback
}
