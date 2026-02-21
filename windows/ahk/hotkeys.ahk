HotkeyFile := A_ScriptDir "\hotkeys.ini"

ActivateWindow(exe, id) {
    ; try to activate window with specific id
    for window in WinGetList("ahk_exe " exe) {
        if window == id {
            WinActivate("ahk_id " window)
            return
        }
    }

    ; fallback: activate first window if any
    for window in WinGetList("ahk_exe " exe) {
        WinActivate("ahk_id " window)
        return
    }


    if exe != "" {
	Run(exe)
    }
}


if FileExist(HotkeyFile) {
    lines := []
    Loop Read, HotkeyFile
        lines.Push(StrSplit(A_LoopReadLine, "|"))

    latest := Map()
    for line in lines {
        exe := Trim(line[2])
        latest[exe] := line ; keep only last occurrence
    }

    ; overwrite file with filtered lines
    FileDelete(HotkeyFile)
    for exe, line in latest {
        FileAppend(Trim(line[1]) "|" Trim(line[2]) "|" Trim(line[3]) "`n", HotkeyFile)
        CreateHotkey(Trim(line[1]), Trim(line[2]), Trim(line[3]))
    }
}

CreateHotkey(kb, exe, id) {
    Hotkey kb, (*) => ActivateWindow(exe, id)
}



>+!r:: {
    RegisterWindowHotkey(">+!", "Add key, pre-added with Right Shift + Alt")
}

^>+!r:: {
    RegisterWindowHotkey("", "Use AHK format like ^!E")
}

RegisterWindowHotkey(prefix, prompt) {
    win := WinActive("A")
    id := "ahk_id " win
    exe := WinGetProcessName(win) ; just the exe name

    ; get full path of running process
    procPath := ""
    for p in ComObjGet("winmgmts:").ExecQuery("Select ExecutablePath from Win32_Process where Name='" exe "'") {
        procPath := p.ExecutablePath
        break
    }
    if !procPath
        procPath := exe  ; fallback if WMI fails

    title := WinGetTitle(id)
    kb := prefix . InputBox(prompt).Value
    if kb {
        MsgBox("Hotkey for '" title "' (" procPath ") is " kb)
        Hotkey kb, (*) => ActivateWindow(procPath, win)
        FileAppend(kb "|" procPath "|" win "`n", HotkeyFile)
    }
}
