Numpad1::{
    ; 2) Three Tabs
    Send "{Tab 3}"

    Sleep 1

    ; 3) Enter
    Send "{Enter}"
}

Numpad2:: {
    SendEvent "{Ctrl down}{Alt down}{Home down}"
    Sleep 30
    SendEvent "{Home up}{Alt up}{Ctrl up}"
}