#Requires AutoHotkey v2.0
#SingleInstance Force

scaleX := A_ScreenWidth / 1920
scaleY := A_ScreenHeight / 1080

low_20 := "match"
low_30 := "match"
low_60 := "match"

high_30 := "match"
high_60 := "unlimited"


CoordMode "Mouse", "Screen"



rbPassthrough := true
rbSent := false 
rclick := false

escape := {
    x: A_ScreenWidth / 2,
    y: (500 * scaleY)
}

phyx := {
    low : (1235 * scaleX),
    high : (1365 * scaleX)
}

phyy := (338 * scaleY)

d_x := phyx.high - phyx.low

fpsx := {
    20 : phyx.low,
    30 : phyx.high,
    60 : phyx.high + d_x
}

fpsy := (396 * scaleY)

Logicx := {
    match : phyx.low,
    unlimited : fpsx.60
}

logicy := (453 * scaleY)

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

busy := false

Change_Fps(target_phy, target_fps, target_logic) {
    global current_fps, current_phy, escape, phyx, phyy, fpsx, fpsy, time, transition, busy, current_logic

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
        busy := false
        BlockInput "MouseMoveOff"

    }
}

ShowSettings() {
    global current_fps, current_phy

    ToolTip("FPS: " current_fps " " current_phy)

    SetTimer(RemoveToolTip, -2500)
}

RemoveToolTip() {
    ToolTip()
}


F1::{
    global moving

    moving := true
}

F2::{
    global moving

    moving := false
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
}

*+F::{
    global current_fps, target_fps, moving, x_pressed, busy, current_phy, low_30, high_60



    if (moving && !x_pressed && !busy){

            busy := true
            if current_fps = 60 {
                Change_Fps("low", 30, low_30)
            }
            else {
                Change_Fps("high", 60, high_60)
            }
    }

}


*+R::{
    global current_fps, target_fps, moving, x_pressed, busy, current_phy, low_20


    if (moving && !x_pressed && !busy){

            busy := true
            if current_fps = 20 {
                Change_Fps("low", 30, low_30)
            }
            else {
                Change_Fps("low", 20, low_20)
            }
    }
}

*+E::{
    global current_fps, target_fps, moving, x_pressed, busy, current_phy, high_30

    if (moving && !x_pressed && !busy){
            busy := true
            Change_Fps("high", 30, high_30)
    }
}

*+Q::{
    global current_fps, target_fps, moving, x_pressed, busy, current_phy, low_60

    if (moving && !x_pressed && !busy){
            busy := true
            Change_Fps("low", 60, low_60)
    }
}
