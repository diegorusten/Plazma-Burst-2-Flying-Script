#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"

; Change this when the config layout changes. If the Version line in
; flying_script.txt does not match, the .txt is deleted and rebuilt with defaults.
VERSION := "1.2.1 Fullscreen"

; =====================================================================
;  Config (plain "key = value" text file)
; =====================================================================
CONFIG_PATH := A_ScriptDir "\fly_settings.txt"

; Options that are written as on/off in the file (stored as 1/0 in memory)
BoolKeys := Map("right_click_passthrough", 1, "tooltips", 1, "overlay_enabled", 1)

; Fixed menu coordinates for fullscreen 16:9, scaled from 1920x1080
scaleX := A_ScreenWidth / 1920
scaleY := A_ScreenHeight / 1080

DefaultConfig() {
    d := Map(
        "version", VERSION,
        "range", 700,
        "range_step", 50,
        "range_min", 200,
        "range_max", A_ScreenWidth,
        "safety", 100,
        "r_limit", 20,
        "timer_ms", 5,
        "right_click_passthrough", "on",
        "tooltips", "on",
        "start", "F1",
        "stop", "F2",
        "overlaytoggle", "ctrl+alt+O",
        "low30_high60_change", "shift+F",
        "low20_low30_change", "shift+R",
        "high30_change", "shift+E",
        "low60_change", "shift+Q",
        "low_20", "match",
        "low_30", "match",
        "low_60", "match",
        "high_30", "match",
        "high_60", "unlimited",
        "key_press_ms_20", 10,
        "key_press_ms_30", 5,
        "key_press_ms_60", 4,
        "transition_ms_20", 70,
        "transition_ms_30", 55,
        "transition_ms_60", 45,
        "last_fps", 20,
        "last_physics", "low",
        "last_logic", "match",
        "overlay_enabled", "on",
        "overlay_x", 20,
        "overlay_y", Round(A_ScreenHeight / 4),
        "overlay_opacity", 210,
        "overlay_font", "Consolas",
        "overlay_font_size", 12,
        "overlay_text_color", "FFFFFF",
        "overlay_background", "101010"
    )
    return d
}

; Order and comments of the generated file (lines starting with # are comments)
ConfigLayout() {
    L := []
    L.Push("# Flying script settings - edit the value after the = sign and restart the script.")
    L.Push("# Lines starting with # are comments. On/off options accept on/off, yes/no, true/false.")
    L.Push("# If the version at the bottom does not match the script, this file is deleted and rebuilt with defaults.")
    L.Push("")
    L.Push("# --- Hotkeys (modifiers: shift, ctrl, alt, win; example: shift+alt+O) ---")
    for k in ["start", "stop", "overlaytoggle", "low30_high60_change", "low20_low30_change", "high30_change", "low60_change"]
        L.Push(k)
    L.Push("")
    L.Push("# --- Logic per mode: match or unlimited ---")
    for k in ["low_20", "low_30", "low_60", "high_30", "high_60"]
        L.Push(k)
    L.Push("")
    L.Push("# --- General ---")
    for k in ["range", "range_step", "range_min", "range_max", "safety", "r_limit", "timer_ms", "right_click_passthrough", "tooltips"]
        L.Push(k)
    L.Push("")
    L.Push("# --- Remembered state (saved on exit) ---")
    for k in ["last_fps", "last_physics", "last_logic"]
        L.Push(k)
    L.Push("")
    L.Push("# --- Overlay (x = gap from right screen edge, y = gap from top, colors are hex RRGGBB) ---")
    for k in ["overlay_enabled", "overlay_x", "overlay_y", "overlay_opacity", "overlay_font", "overlay_font_size", "overlay_text_color", "overlay_background"]
        L.Push(k)
    L.Push("")
    L.Push("# --- Timings (ms), per FPS ---")
    for k in ["key_press_ms_20", "key_press_ms_30", "key_press_ms_60", "transition_ms_20", "transition_ms_30", "transition_ms_60"]
        L.Push(k)
    L.Push("")
    L.Push("# --- Version (keep this last; must match the script) ---")
    L.Push("version")
    return L
}

IsOn(v) {
    return RegExMatch(String(v), "i)^(on|true|yes|1)$") ? true : false
}

FmtValue(k, v) {
    global BoolKeys
    if BoolKeys.Has(k)
        return IsOn(v) ? "on" : "off"
    return String(v)
}

WriteConfig(c) {
    global CONFIG_PATH
    out := ""
    done := Map()
    for line in ConfigLayout() {
        if (line = "" || SubStr(line, 1, 1) = "#") {
            out .= line "`r`n"
            continue
        }
        if !c.Has(line)
            continue
        out .= line " = " FmtValue(line, c[line]) "`r`n"
        done[line] := 1
    }

    f := FileOpen(CONFIG_PATH, "w", "UTF-8-RAW")
    f.Write(out)
    f.Close()
}

; Fill in missing keys / fix wrong types using the defaults
MergeDefaults(def, user) {
    for k, dv in def {
        if (!user.Has(k) || user[k] = "") {
            user[k] := dv
            continue
        }
        if (dv is Number) {
            if IsNumber(user[k])
                user[k] := user[k] + 0
            else
                user[k] := dv
        }
    }
}

LoadConfig() {
    global CONFIG_PATH, VERSION, BoolKeys
    def := DefaultConfig()

    ; Missing file -> create it with default values
    if !FileExist(CONFIG_PATH) {
        WriteConfig(def)
        return def
    }

    user := Map()
    try {
        for line in StrSplit(FileRead(CONFIG_PATH, "UTF-8"), "`n") {
            line := Trim(line, " `t`r")
            if (line = "" || SubStr(line, 1, 1) = ";" || SubStr(line, 1, 1) = "#")
                continue
            p := InStr(line, "=")
            if !p
                continue
            user[StrLower(Trim(SubStr(line, 1, p - 1)))] := Trim(SubStr(line, p + 1))
        }
    }

    ; Wrong or missing version -> delete the file and use the standard configuration
    if (!user.Has("version") || user["version"] != VERSION) {
        try FileDelete(CONFIG_PATH)
        WriteConfig(def)
        TrayTip("The config version didn't match (" VERSION "). flying_script.txt was reset to defaults.", "Flying script")
        user := def
    } else {
        MergeDefaults(def, user)
    }

    for k in BoolKeys
        user[k] := IsOn(user[k]) ? 1 : 0

    return user
}

Clamp(v, lo, hi) {
    return Max(lo, Min(hi, v))
}

cfg := LoadConfig()

; --- sanitize the remembered state ---------------------------------
cfg["last_physics"] := StrLower(cfg["last_physics"])
cfg["last_logic"] := StrLower(cfg["last_logic"])
if !(cfg["last_fps"] = 20 || cfg["last_fps"] = 30 || cfg["last_fps"] = 60)
    cfg["last_fps"] := 20
if !(cfg["last_physics"] = "low" || cfg["last_physics"] = "high")
    cfg["last_physics"] := "low"
if !(cfg["last_logic"] = "match" || cfg["last_logic"] = "unlimited")
    cfg["last_logic"] := "match"

for k in ["low_20", "low_30", "low_60", "high_30", "high_60"] {
    cfg[k] := StrLower(cfg[k])
    if !(cfg[k] = "match" || cfg[k] = "unlimited")
        cfg[k] := "unlimited"
}

; --- settings -------------------------------------------------------
RANGE_MIN := cfg["range_min"]
RANGE_MAX := cfg["range_max"]
RANGE_STEP := cfg["range_step"]
RANGE := Clamp(cfg["range"], RANGE_MIN, RANGE_MAX)
SAFETY := cfg["safety"]
R_limit := cfg["r_limit"]
TIMER_MS := cfg["timer_ms"]

low_20 := cfg["low_20"]
low_30 := cfg["low_30"]
low_60 := cfg["low_60"]
high_30 := cfg["high_30"]
high_60 := cfg["high_60"]

MENU_ESCAPE_Y := Round(500 * scaleY)
PHY_LOW_X := Round(1235 * scaleX)
PHY_HIGH_X := Round(1365 * scaleX)
PHY_MENU_Y := Round(338 * scaleY)
FPS_MENU_Y := Round(396 * scaleY)
LOGIC_MENU_Y := Round(453 * scaleY)

h_range := RANGE / 2
R_released := R_limit + 1
Passthrough := false

MouseGetPos(&x, &y)
x_positive := x + h_range
x_negative := x - h_range

State := {
    First: true,
    F1press: false,
    moving: false,
    x_pressed: false,
    busy: false,
    direction: 1
}

rbPassthrough := cfg["right_click_passthrough"] ? true : false
rbSent := false
rclick := false

escape := {
    x: A_ScreenWidth / 2,
    y: MENU_ESCAPE_Y
}

phyx := Map("low", PHY_LOW_X, "high", PHY_HIGH_X)
phyy := PHY_MENU_Y

d_x := phyx["high"] - phyx["low"]

fpsx := Map("20", phyx["low"], "30", phyx["high"], "60", phyx["high"] + d_x)
fpsy := FPS_MENU_Y

Logicx := Map("match", phyx["low"], "unlimited", fpsx["60"])
logicy := LOGIC_MENU_Y

keyMs := Map("20", cfg["key_press_ms_20"], "30", cfg["key_press_ms_30"], "60", cfg["key_press_ms_60"])
transMs := Map("20", cfg["transition_ms_20"], "30", cfg["transition_ms_30"], "60", cfg["transition_ms_60"])

current_fps := cfg["last_fps"]
current_phy := cfg["last_physics"]
current_logic := cfg["last_logic"]

; --- overlay ---------------------------------------------------------
ov := 0
ovStatus := 0
ovInfo := 0
ovVisible := false
ovLastStatus := ""

CreateOverlay() {
    global ov, ovStatus, ovInfo, ovVisible, cfg

    ; Click-through (E0x20), never takes focus (E0x08000000), always on top
    ov := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 -DPIScale")
    ov.MarginX := 20
    ov.MarginY := 6
    ov.BackColor := cfg["overlay_background"]
    ov.SetFont("s" cfg["overlay_font_size"] " w700 c" cfg["overlay_text_color"], cfg["overlay_font"])
    ovStatus := ov.AddText("w300", "STOPPED")
    ov.SetFont("s" cfg["overlay_font_size"] " w400 c" cfg["overlay_text_color"], cfg["overlay_font"])
    ovInfo := ov.AddText("w300 y+2 r2", "")

    UpdateOverlay()
    if cfg["overlay_enabled"]
        ShowOverlay()
}

ShowOverlay() {
    global ov, ovVisible, cfg

    ; Size the window while hidden so we know its width
    ov.Show("Hide AutoSize")
    ov.GetPos(, , &w)

    ; overlay_x is the gap from the RIGHT edge of the screen, overlay_y the gap from the top
    ov.Show("x" (A_ScreenWidth - w - cfg["overlay_x"]) " y" cfg["overlay_y"] " NoActivate")
    WinSetTransparent(Clamp(cfg["overlay_opacity"], 0, 255), ov)
    ovVisible := true
}

HideOverlay() {
    global ov, ovVisible
    ov.Hide()
    ovVisible := false
}

ToggleOverlay(*) {
    global ovVisible
    if ovVisible
        HideOverlay()
    else
        ShowOverlay()
}

UpdateOverlay() {
    global ov, ovStatus, ovInfo, ovLastStatus
    global State, rclick, rbPassthrough, current_fps, current_phy, current_logic, RANGE

    if !ov
        return

    if State.busy {
        txt := "SWITCHING..."
        col := "FFC400"
    }
    else if !State.moving {
        txt := "STOPPED"
        col := "FF5555"
    }
    else if (rclick && current_fps = 60 && current_phy = "high") {
        txt := "SWEEPING"
        col := "55FF55"
    }
    else {
        txt := "ARMED"
        col := "55AAFF"
    }

    if (txt != ovLastStatus) {
        ovStatus.SetFont("c" col)
        ovStatus.Value := txt
        ovLastStatus := txt
    }

    rb := rbPassthrough ? "ON" : "OFF"
    ovInfo.Value := "FPS " current_fps " | " current_phy " | Range " RANGE
        . "`nR-click " rb
}

CreateOverlay()

; --- save on exit (range, FPS / physics / logic, toggles) -----------
OnExit(SaveAndExit)

SaveAndExit(*) {
    global cfg, RANGE, rbPassthrough, ovVisible, current_fps, current_phy, current_logic
    cfg["range"] := RANGE
    cfg["right_click_passthrough"] := rbPassthrough ? 1 : 0
    cfg["last_fps"] := current_fps
    cfg["last_physics"] := current_phy
    cfg["last_logic"] := current_logic
    cfg["overlay_enabled"] := ovVisible ? 1 : 0
    try WriteConfig(cfg)
}

; --- configurable hotkeys -------------------------------------------
; Turns "shift+alt+O" into AutoHotkey's "+!O" (optionally with the * wildcard prefix)
ParseHotkey(text, wildcard := false) {
    parts := StrSplit(Trim(text), "+")
    key := Trim(parts.Pop())
    mods := ""
    for p in parts {
        p := StrLower(Trim(p))
        if (p = "")
            continue
        if (p = "shift")
            mods .= "+"
        else if (p = "alt")
            mods .= "!"
        else if (p = "ctrl" || p = "control")
            mods .= "^"
        else if (p = "win")
            mods .= "#"
        else
            throw Error("Unknown modifier '" p "'")
    }
    return (wildcard ? "*" : "") mods key
}

RegisterHotkey(keyText, fn, wildcard := false) {
    try {
        Hotkey(ParseHotkey(keyText, wildcard), fn, "On")
    } catch as e {
        MsgBox("Invalid hotkey '" keyText "' in flying_script.txt:`n" e.Message, "Flying script", "Icon!")
    }
}

RegisterHotkey(cfg["start"], StartMoving)
RegisterHotkey(cfg["stop"], StopMoving)
RegisterHotkey(cfg["overlaytoggle"], ToggleOverlay)
RegisterHotkey(cfg["low30_high60_change"], SwitchLow30High60, true)
RegisterHotkey(cfg["low20_low30_change"], SwitchLow20Low30, true)
RegisterHotkey(cfg["high30_change"], SwitchHigh30, true)
RegisterHotkey(cfg["low60_change"], SwitchLow60, true)

; True if Windows (not AHK's hook) says the right button is physically down
OSRButtonDown() {
    return (DllCall("GetAsyncKeyState", "int", 0x02) & 0x8000) ? true : false
}

; =====================================================================
;  Core logic (unchanged behaviour)
; =====================================================================
MoveMouse() {
    global State, x_negative, x_positive, x, RANGE, SAFETY, y, h_range, rclick, rbSent, current_fps, current_phy, R_released, R_limit

    if !State.moving
        return

    if rclick {
        hookUp := !GetKeyState("RButton", "P")
        osUp := rbSent && !OSRButtonDown()   ; hook missed the up, OS saw it
        if (hookUp || osUp) {
            rclick := false
            if rbSent {
                Send "{Blind}{RButton up}"
                rbSent := false
            }
        }
    }

    if (rclick && !State.busy && (current_fps = 60) && (current_phy = "high")) {
        State.x_pressed := true
        State.direction *= -1
        MouseGetPos(&x, &y)

        if State.First && (R_released >= R_limit) {
            x_positive := x + h_range
            x_negative := x - h_range
            State.First := false
        }

        if State.direction = 1 {
            ; State.direction = 1: X moves to the right
            ; if x is within SAFETY of x_positive, reset
            if (Abs(x_positive - x) < SAFETY) {
                MouseMove(x_positive, y)
            }
            else {
                x_negative := x
                MouseMove(x + RANGE, y)
            }
        }
        else {
            ; State.direction = -1: X moves to the left
            if State.F1press && (R_released < R_limit) {
                MouseMove(x_negative, y)
                State.F1press := false
                R_released := 0
            }
            else if State.F1press {
                MouseMove(x - h_range, y)
                State.F1press := false
                R_released := 0
            }
            else {
                if (Abs(x - x_negative) < SAFETY) {
                    MouseMove(x_negative, y)
                }
                else {
                    x_positive := x
                    MouseMove(x - RANGE, y)
                }
            }
        }
    }
    else if State.x_pressed {
        MouseMove((x_positive + x_negative) / 2, y)
        State.x_pressed := false
        State.F1press := true
        State.First := true
        State.direction := 1
        R_released += 1
    }
    else if R_released <= R_limit {
        if (Mod(R_released, 2) = 1)  {
            MouseMove(2, 0, 0, "R")
        }
        else {
            MouseMove(-2, 0, 0, "R")
        }
        R_released += 1
        Send "{Blind}{X up}"
    }
}

Change_Fps(target_phy, target_fps, target_logic) {
    global current_fps, current_phy, escape, phyx, phyy, fpsx, fpsy, keyMs, transMs, State, current_logic, Logicx, logicy

    try {
        MouseGetPos(&x, &y)

        k := keyMs[String(current_fps)]
        t := transMs[String(current_fps)]

        UpdateOverlay()

        BlockInput "MouseMove"

        Send "{Esc down}"
        Sleep k
        Send "{Esc up}"

        MouseMove(escape.x, escape.y)

        Sleep t

        Click "Down"
        Sleep k
        Click "Up"

        if current_phy != target_phy {
            MouseMove(phyx[target_phy], phyy)
            Sleep t
            Click "Down"
            Sleep k
            Click "Up"
        }

        if current_fps != target_fps {
            MouseMove(fpsx[String(target_fps)], fpsy)
            Sleep t
            Click "Down"
            Sleep k
            Click "Up"
        }

        if current_logic != target_logic {
            MouseMove(Logicx[target_logic], logicy)
            Sleep t
            Click "Down"
            Sleep k
            Click "Up"
        }

        MouseMove(x, y)

        Send "{Esc down}"
        Sleep k
        Send "{Esc up}"

        Sleep k

        Send "{Esc down}"
        Sleep k
        Send "{Esc up}"

        current_fps := target_fps
        current_phy := target_phy
        current_logic := target_logic
        ShowSettings()
    }
    finally {
        State.busy := false
        BlockInput "MouseMoveOff"
        UpdateOverlay()
    }
}

Tip(text, ms := 2500) {
    global cfg
    if !cfg["tooltips"]
        return

    hwnd := ToolTip(text)

    WinSetExStyle("+0x20", hwnd)   ; click-through

    SetTimer(RemoveToolTip, -ms)
}

ShowSettings() {
    global current_fps, current_phy
    Tip("FPS: " current_fps " " current_phy)
}

Show_RANGE(ms := 2500) {
    global RANGE

    hwnd := ToolTip("Range: " Range)

    WinSetExStyle("+0x20", hwnd)   ; click-through

    SetTimer(RemoveToolTip, -ms)

}

RemoveToolTip() {
    ToolTip()
}


; =====================================================================
;  Start / stop (default F1 / F2, configurable in the txt)
; =====================================================================
StartMoving(*) {
    global State, TIMER_MS, Passthrough, rbPassthrough

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
    if Passthrough {
        rbPassthrough := false
        Passthrough := false
    }

    SetTimer(MoveMouse, TIMER_MS)
    UpdateOverlay()
}

StopMoving(*) {
    global x_positive, x_negative, y, State, rbPassthrough, Passthrough

    State.moving := false
    State.F1press := false
    SetTimer(MoveMouse, 0)
    if State.x_pressed {
        MouseGetPos(&x, &y)
        MouseMove((x_positive + x_negative) / 2, y)
        State.x_pressed := false
    }

    if !rbPassthrough {
        rbPassthrough := true
        Passthrough := true
    }
    UpdateOverlay()

}


; =====================================================================
;  Right click
; =====================================================================
$*RButton:: {
    global rbPassthrough, rbSent, rclick, current_fps, current_phy

    if GetKeyState("Alt", "P") {
        rbPassthrough := !rbPassthrough
        Tip("Right click: " (rbPassthrough ? "ON" : "OFF"), 1500)
        UpdateOverlay()
        return
    }

    if rbPassthrough {
        rbSent := true
        Send "{Blind}{RButton down}"
    }
    rclick := true

    if (current_fps != 60 && current_phy != "high") {
        ShowSettings()
    }
    UpdateOverlay()
}

$*RButton up:: {
    global rbSent, rclick

    if rbSent {
        Send "{Blind}{RButton up}"
        rbSent := false
    }
    rclick := false
    UpdateOverlay()
}


; =====================================================================
;  FPS / physics switching (keys come from the txt)
; =====================================================================
SwitchLow30High60(*) {
    global current_fps, State, low_30, high_60

    if (State.moving && !State.x_pressed && !State.busy) {
        State.busy := true
        if current_fps = 60 {
            Change_Fps("low", 30, low_30)
        }
        else {
            Change_Fps("high", 60, high_60)
        }
    }
}

SwitchLow20Low30(*) {
    global current_fps, State, low_20, low_30

    if (State.moving && !State.x_pressed && !State.busy) {
        State.busy := true
        if current_fps = 20 {
            Change_Fps("low", 30, low_30)
        }
        else {
            Change_Fps("low", 20, low_20)
        }
    }
}

SwitchHigh30(*) {
    global State, high_30, current_fps, current_phy, low_30

    if (State.moving && !State.x_pressed && !State.busy) {

        State.busy := true

        if current_fps = 30 && current_phy = "high" {
            Change_Fps("low", 30, low_30)
        }
        else {
            Change_Fps("high", 30, high_30)
        }
    }
}

SwitchLow60(*) {
    global State, low_60, current_fps, current_phy, low_30

    if (State.moving && !State.x_pressed && !State.busy) {

        State.busy := true

        if current_fps = 60 && current_phy = "low" {
            Change_Fps("low", 30, low_30)
        }
        else {
            Change_Fps("low", 60, low_60)
        }
    }
}


; =====================================================================
;  Range (Shift + mouse wheel)
; =====================================================================
*+WheelDown:: {
    global RANGE, h_range, RANGE_MIN, RANGE_STEP

    if RANGE > RANGE_MIN {
        RANGE := Max(RANGE_MIN, RANGE - RANGE_STEP)
        h_range := RANGE / 2
        Show_RANGE()
        UpdateOverlay()
    }
}

*+WheelUp:: {
    global RANGE, h_range, RANGE_MAX, RANGE_STEP

    if RANGE < RANGE_MAX {
        RANGE := Min(RANGE_MAX, RANGE + RANGE_STEP)
        h_range := RANGE / 2
        Show_RANGE()
        UpdateOverlay()
    }
}
