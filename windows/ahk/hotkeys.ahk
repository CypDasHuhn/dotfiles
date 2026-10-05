HotkeyFile := A_ScriptDir "\hotkeys.ini"

ActivateWindow(title, id) {
    if id && WinExist("ahk_id " id) {
        if title = "" || InStr(WinGetTitle(id), title) {
            FocusWindow(id)
            return
        }
    }

    if title != "" {
        for hwnd in WinGetList() {
            if InStr(WinGetTitle(hwnd), title) {
                FocusWindow(hwnd)
                return
            }
        }
    }
}

FocusWindow(hwnd) {
    if WinGetClass(hwnd) = "RAIL_WINDOW"
        ForceFocusRail(hwnd)
    else
        WinActivate(hwnd)
}

ForceFocusRail(hwnd) {
    if DllCall("IsIconic", "Ptr", hwnd)
        DllCall("ShowWindow", "Ptr", hwnd, "Int", 9)

    cur := DllCall("GetCurrentThreadId", "UInt")
    fg := DllCall("GetForegroundWindow", "Ptr")
    fgThread := DllCall("GetWindowThreadProcessId", "Ptr", fg, "Ptr", 0)
    targetThread := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "Ptr", 0)

    DllCall("AllowSetForegroundWindow", "UInt", 0xFFFFFFFF)
    DllCall("AttachThreadInput", "UInt", fgThread, "UInt", cur, "Int", 1)
    DllCall("AttachThreadInput", "UInt", targetThread, "UInt", cur, "Int", 1)
    DllCall("SetForegroundWindow", "Ptr", hwnd)
    DllCall("BringWindowToTop", "Ptr", hwnd)
    DllCall("SetFocus", "Ptr", hwnd)
    DllCall("AttachThreadInput", "UInt", targetThread, "UInt", cur, "Int", 0)
    DllCall("AttachThreadInput", "UInt", fgThread, "UInt", cur, "Int", 0)
}

if FileExist(HotkeyFile) {
    lines := []
    Loop Read, HotkeyFile
        lines.Push(StrSplit(A_LoopReadLine, "|"))

    latest := Map()
    for line in lines {
        if line.Length < 3
            continue
        latest[Trim(line[2])] := line
    }

    FileDelete(HotkeyFile)
    for title, line in latest {
        kb := Trim(line[1])
        id := Trim(line[3]) != "" ? Integer(Trim(line[3])) : 0
        FileAppend(kb "|" title "|" id "`n", HotkeyFile)
        CreateHotkey(kb, title, id)
    }
}

CreateHotkey(kb, title, id) {
    Hotkey kb, (*) => ActivateWindow(title, id)
}

>+!r:: RegisterWindowHotkey(">+!", "Add key, pre-added with Right Shift + Alt")

^>+!r:: RegisterWindowHotkey("", "Use AHK format like ^!E")

RegisterWindowHotkey(prefix, prompt) {
    win := WinActive("A")
    if !win
        return

    title := WinGetTitle(win)
    kb := prefix . InputBox(prompt).Value
    if !kb
        return

    MsgBox("Hotkey for '" title "' is " kb)
    Hotkey kb, (*) => ActivateWindow(title, win)
    FileAppend(kb "|" title "|" win "`n", HotkeyFile)
}
