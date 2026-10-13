#Requires AutoHotkey v2.0
#SingleInstance Force


RANGE := 700

low_20 := "match"
low_30 := "match"
low_60 := "match"

high_30 := "match"
high_60 := "unlimited"

MENU_ESCAPE_Y := 500
PHY_LOW_X := 1235
PHY_HIGH_X := 1365
PHY_MENU_Y := 338
FPS_MENU_Y := 396
LOGIC_MENU_Y := 453

SAFETY := 100
h_range := RANGE/2
R_limit := 20
R_released := R_limit + 1


MouseGetPos(&x, &y)
x_positive := x + h_range
x_negative := x- h_range

CoordMode "Mouse", "Screen"

State := {
    First: true,
    F1press: false,
    moving: false,
    x_pressed: false,
    busy: false,
    direction: 1
}

rbPassthrough := true
rbSent := false 
rclick := false

scaleX := A_ScreenWidth / 1920
scaleY := A_ScreenHeight / 1080

escape := {
    x: A_ScreenWidth / 2,
    y: MENU_ESCAPE_Y * scaleY
}

phyx := {
    low : PHY_LOW_X * scaleX,
    high : PHY_HIGH_X * scaleX
}

phyy := PHY_MENU_Y * scaleY

d_x := phyx.high - phyx.low

fpsx := {
    20 : phyx.low,
    30 : phyx.high,
    60 : phyx.high + d_x
}

fpsy := FPS_MENU_Y * scaleY

Logicx := {
    match : phyx.low,
    unlimited : fpsx.60
}

logicy := LOGIC_MENU_Y * scaleY

time := {
    20 : 10,
    30 : 5,
    60 : 4
}

transition := {
    20 : 70,
    30 : 55,
    60 : 45
}

current_fps := 20
current_phy := "low"
current_logic := "match"



MoveMouse() {
    global State, x_negative, x_positive, x, RANGE, SAFETY, y, h_range, rclick, rbSent, current_fps, current_phy, R_released, R_limit

    if !State.moving
        return

    if (rclick && !GetKeyState("RButton", "P")) {
        rclick := false
        if rbSent {
            Send "{Blind}{RButton up}"
            rbSent := false
        }
    }

    if (rclick && !State.busy && (current_fps = 60) && (current_phy = "high")){
    State.x_pressed := true
    State.direction *= -1
    MouseGetPos(&x, &y)
    
    if State.First && (R_released >= R_limit) {
        x_positive := x + h_range
        x_negative := x- h_range
        State.First := false
    }

    
    


    if State.direction = 1 {
;State.direction = 1, X se mueve a la derecha
; x = x negative
; si x es similar a x_positive en rango de SAFETY entonces se resetea

        if (Abs(x_positive - x) < SAFETY) {
	    MouseMove(x_positive, y)
	}
	else {
	    x_negative := x
            MouseMove(x+RANGE, y)
	}
    }
    else {

; State.direction = -1 x se mueve a la izquierda
; x = x positive
; si x es similar a x_negative en rango de SAFETY 
        
        if State.F1press && (R_released < R_limit){
	    MouseMove(x_negative, y)
	    State.F1press := false
            R_released := 0  
	}
        else if State.F1press {
	    MouseMove(x-h_range, y)
	    State.F1press := false
            R_released := 0
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
    else if State.x_pressed {
        MouseMove((x_positive+x_negative)/2, y)
        State.x_pressed :=false
        State.F1press := true
        State.First := true
        State.direction := 1
        R_released += 1
    }
    else if R_released <= R_limit {
        R_released += 1     
    }
}

Change_Fps(target_phy, target_fps, target_logic) {
    global current_fps, current_phy, escape, phyx, phyy, fpsx, fpsy, time, transition, State, current_logic

    try {
        MouseGetPos(&x, &y)

        BlockInput "MouseMove"

        Send "{Esc down}"
        Sleep time.%current_fps%
        Send "{Esc up}"

        MouseMove(escape.x, escape.y)

        sleep transition.%current_fps%

        Click "Down"
        Sleep time.%current_fps%
        Click "Up"

        if current_phy != target_phy {

            MouseMove(phyx.%target_phy%, phyy)

            sleep transition.%current_fps%

            Click "Down"
            Sleep time.%current_fps%
            Click "Up"
        }

	if current_fps!= target_fps {

            MouseMove(fpsx.%target_fps%, fpsy)

            sleep transition.%current_fps%

            Click "Down"
            Sleep time.%current_fps%
            Click "Up"
        }

	if current_logic != target_logic {

            MouseMove(logicx.%target_logic%, logicy)

            sleep transition.%current_fps%

            Click "Down"
            Sleep time.%current_fps%
            Click "Up"
        }

        MouseMove(x, y)

        Send "{Esc down}"
        Sleep time.%current_fps%
        Send "{Esc up}"

        sleep time.%current_fps%

        Send "{Esc down}"
        Sleep time.%current_fps%
        Send "{Esc up}"
        

        current_fps := target_fps
        current_phy := target_phy
        current_logic := target_logic
        ShowSettings()
    }
    finally {
        State.busy := false
        BlockInput "MouseMoveOff"

    }
}

ShowSettings() {
    global current_fps, current_phy

    ToolTip("FPS: " current_fps " " current_phy)

    SetTimer(RemoveToolTip, -2500)
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
    global State
    
    if State.moving {
        if State.x_pressed {
	    State.F1press := false
	}
        else {
            State.F1press := true
            State.direction := 1
        }
	
    }
    else {
        State.F1press := true
        State.First := true
        State.direction := 1
    }
    State.moving := true
    SetTimer(MoveMouse, 5)

}

F2::{
    global x_positive, x_negative, y, State

    State.moving := false
    State.F1press := false
    SetTimer(MoveMouse, 0)
    if State.x_pressed{
        MouseGetPos(&x, &y)
        MouseMove((x_positive+x_negative)/2, y)
        State.x_pressed := false
    }
}

$*RButton::{
    global rbPassthrough, rbSent, rclick, current_fps, current_phy

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
    
    if (current_fps != 60 && current_phy != "high")  {
        ShowSettings()
    }
}

$*RButton up::{
    global rbSent, rclick

    if rbSent {
        Send "{Blind}{RButton up}"
        rbSent := false
    }
    rclick := false
}

*+F::{
    global current_fps, target_fps, State, current_phy, low_30, high_60



    if (State.moving && !State.x_pressed && !State.busy){

            State.busy := true
            if current_fps = 60 {
                Change_Fps("low", 30, low_30)
            }
            else {
                Change_Fps("high", 60, high_60)
            }
    }

}


*+R::{
    global current_fps, target_fps, State, current_phy, low_20


    if (State.moving && !State.x_pressed && !State.busy){

            State.busy := true
            if current_fps = 20 {
                Change_Fps("low", 30, low_30)
            }
            else {
                Change_Fps("low", 20, low_20)
            }
    }
}

*+E::{
    global current_fps, target_fps, State, current_phy, high_30

    if (State.moving && !State.x_pressed && !State.busy){
            State.busy := true
            Change_Fps("high", 30, high_30)
    }
}

*+Q::{
    global current_fps, target_fps, State, current_phy, low_60

    if (State.moving && !State.x_pressed && !State.busy){
            State.busy := true
            Change_Fps("low", 60, low_60)
    }
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
