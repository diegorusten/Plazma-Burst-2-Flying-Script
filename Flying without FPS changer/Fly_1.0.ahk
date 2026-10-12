#Requires AutoHotkey v2.0
#SingleInstance Force


RANGE := 900 * A_ScreenWidth / 1920


First := true
SAFETY := 100
h_range := RANGE/2
F1press := false
moving := false
x_pressed := false
direction := 1


rbPassthrough := true
rbSent := false 
rclick := false


MoveMouse() {
    global moving, direction, First, x_negative, x_positive, x, RANGE, SAFETY, F1press, y, x_pressed, h_range, rclick, rbSent

    if !moving
        return

    if (rclick && !GetKeyState("RButton", "P")) {
        rclick := false
        if rbSent {
            Send "{Blind}{RButton up}"
            rbSent := false
        }
    }

    if rclick {
    x_pressed := true

    direction *= -1
    MouseGetPos(&x, &y)

    if First {
        x_positive := x + h_range
        x_negative := x- h_range
        First := false
    }


    if direction = 1 {

        if (Abs(x_positive - x) < SAFETY) {
	    MouseMove(x_positive, y)
	}
	else {
	    x_negative := x
            MouseMove(x+RANGE, y)
	}
    }
    else {

        if F1press {
	    MouseMove(x-h_range, y)
	    F1press := false
	}

	else {
            if (Abs(x - x_negative) < SAFETY) {
	        MouseMove(x_negative, y)
	    }
	    else {
	        x_positive := x
                MouseMove(x-RANGE, y)
	    }
	}
    }

    }
    else if x_pressed {
        MouseMove((x_positive+x_negative)/2, y)
        x_pressed :=false
        F1press := true
        First := true
        direction := 1
    }
}


Show_RANGE() {
    global RANGE

    ToolTip("Range: " RANGE)

    SetTimer(RemoveToolTip, -2500)
}


RemoveToolTip() {
    ToolTip()
}


F1::{
    global F1press, First, direction, moving, x_pressed
    
    if moving {
        if x_pressed {
	    F1press := false
	}
        else {
            F1press := true
            direction := 1
        }
	
    }
    else {
        F1press := true
        First := true
        direction := 1
    }
    moving := true
    SetTimer(MoveMouse, 5)

}

F2::{
    global x_positive, x_negative, y, moving, x_pressed, F1press

    moving := false
    F1press := false
    SetTimer(MoveMouse, 0)
    if x_pressed{
        MouseGetPos(&x, &y)
        MouseMove((x_positive+x_negative)/2, y)
        x_pressed := false
    }
}

$*RButton::{
    global rbPassthrough, rbSent, rclick

    if GetKeyState("Alt", "P") {
        rbPassthrough := !rbPassthrough
        ToolTip("Right click: " (rbPassthrough ? "ON" : "OFF"))
        SetTimer(() => ToolTip(), -1500)
        return
    }

    if rbPassthrough {
        rbSent := true
        Send "{Blind}{RButton down}"
    }
    rclick := true
}

$*RButton up::{
    global rbSent

    if rbSent {
        Send "{Blind}{RButton up}"
        rbSent := false
    }
    rclick := false
}


*+WheelDown:: {
    global RANGE, h_range

    if RANGE > 200 {
        RANGE -= 50
        h_range := RANGE / 2
        show_RANGE()
    }
}

*+WheelUp:: {
    global RANGE, h_range

    if RANGE < 2000 {
        RANGE += 50
        h_range := RANGE / 2
        show_RANGE()
    }
}
