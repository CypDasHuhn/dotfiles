#Requires AutoHotkey v2.0
#SingleInstance force
ListLines 0
SendMode "Input"
SetWorkingDir A_ScriptDir
KeyHistory 0
#WinActivateForce
ProcessSetPriority "H"
SetWinDelay -1
SetControlDelay -1
#Include %A_LineFile%\..\VD.ah2

; wrapping / cycle back to first desktop when at the last
^#left::VD.goToRelativeDesktopNum(-1)
^#right::VD.goToRelativeDesktopNum(+1)

; move window to left and follow it
+^#left::VD.MoveWindowToRelativeDesktopNum("A", -1).follow()
; move window to right and follow it
+^#right::VD.MoveWindowToRelativeDesktopNum("A", 1).follow()

toggle := false  ; global variable

^Space:: {
    global toggle
    toggle := !toggle
    if toggle
        Send("^#{Right}")  ; switch to desktop 2
    else
        Send("^#{Left}")   ; switch back to desktop 1
}
