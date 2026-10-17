#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"
scaleX := A_ScreenWidth / 1920
scaleY := A_ScreenHeight / 1080

; =====================================================================
;  Minimal JSON reader / writer (AHK v2 has no native JSON)
; =====================================================================
class Json {
    ; Keys whose numeric value (1/0) must be written as true/false
    static BoolKeys := Map("enabled", 1, "right_click_passthrough", 1, "tooltips", 1)

    static Parse(text) {
        return Json.Reader(text).Parse()
    }

    static Dump(v, ind := "", key := "") {
        if (v is Map) {
            if (v.Count = 0)
                return "{}"
            out := "{`n"
            i := 0
            for k, val in v {
                i++
                sep := (i < v.Count) ? "," : ""
                out .= ind "  " '"' k '": ' Json.Dump(val, ind "  ", k) sep "`n"
            }
            return out ind "}"
        }
        if (v is Array) {
            parts := ""
            for i, val in v
                parts .= (i > 1 ? ", " : "") Json.Dump(val, ind, key)
            return "[" parts "]"
        }
        if (v is Number) {
            if Json.BoolKeys.Has(key)
                return v ? "true" : "false"
            return String(v)
        }
        return '"' Json.Esc(v) '"'
    }

    static Esc(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`t", "\t")
        return s
    }

    class Reader {
        __New(text) {
            this.t := text
            this.i := 1
            this.n := StrLen(text)
        }

        Parse() {
            v := this.Value()
            this.Ws()
            if (this.i <= this.n)
                throw Error("Unexpected text at position " this.i)
            return v
        }

        Peek() => SubStr(this.t, this.i, 1)

        Ws() {
            while (this.i <= this.n && InStr(" `t`r`n", SubStr(this.t, this.i, 1)))
                this.i++
        }

        Value() {
            this.Ws()
            c := this.Peek()
            if (c = "{")
                return this.Obj()
            if (c = "[")
                return this.Arr()
            if (c = '"')
                return this.Str()
            if (SubStr(this.t, this.i, 4) = "true") {
                this.i += 4
                return 1
            }
            if (SubStr(this.t, this.i, 5) = "false") {
                this.i += 5
                return 0
            }
            if (SubStr(this.t, this.i, 4) = "null") {
                this.i += 4
                return ""
            }
            return this.Num()
        }

        Obj() {
            m := Map()
            this.i++
            this.Ws()
            if (this.Peek() = "}") {
                this.i++
                return m
            }
            loop {
                this.Ws()
                k := this.Str()
                this.Ws()
                if (this.Peek() != ":")
                    throw Error("Expected ':' at position " this.i)
                this.i++
                m[k] := this.Value()
                this.Ws()
                c := this.Peek()
                this.i++
                if (c = "}")
                    break
                if (c != ",")
                    throw Error("Expected ',' or '}' at position " (this.i - 1))
            }
            return m
        }

        Arr() {
            a := []
            this.i++
            this.Ws()
            if (this.Peek() = "]") {
                this.i++
                return a
            }
            loop {
                a.Push(this.Value())
                this.Ws()
                c := this.Peek()
                this.i++
                if (c = "]")
                    break
                if (c != ",")
                    throw Error("Expected ',' or ']' at position " (this.i - 1))
            }
            return a
        }

        Str() {
            if (this.Peek() != '"')
                throw Error("Expected string at position " this.i)
            this.i++
            out := ""
            while (this.i <= this.n) {
                c := this.Peek()
                this.i++
                if (c = '"')
                    return out
                if (c = "\") {
                    e := this.Peek()
                    this.i++
                    if (e = "n")
                        out .= "`n"
                    else if (e = "t")
                        out .= "`t"
                    else if (e = "r")
                        out .= "`r"
                    else if (e = "u") {
                        out .= Chr("0x" SubStr(this.t, this.i, 4))
                        this.i += 4
                    }
                    else
                        out .= e
                } else {
                    out .= c
                }
            }
            throw Error("Unterminated string")
        }

        Num() {
            if !RegExMatch(this.t, "A)-?\d+(\.\d+)?([eE][+-]?\d+)?", &m, this.i)
                throw Error("Unexpected character at position " this.i)
            this.i += StrLen(m[0])
            return m[0] + 0
        }
    }
}

; =====================================================================
;  Config
; =====================================================================
CONFIG_PATH := A_ScriptDir "\flying_script.json"

DefaultConfig() {
    return Map(
        "range", 700,
        "range_step", 50,
        "range_min", 200,
        "range_max", A_ScreenWidth,
        "safety", 100,
        "r_limit", 20,
        "timer_ms", 5,
        "right_click_passthrough", 1,
        "tooltips", 1,
        "hotkeys", Map("start", "F1", "stop", "F2", "overlay", "^!o"),
        "menu", Map(
            "escape_y", 500 * scaleY,
            "phy_low_x", 1235 * scaleX,
            "phy_high_x", 1365 * scaleX,
            "phy_menu_y", 338 * scaleY,
            "fps_menu_y", 396 * scaleY,
            "logic_menu_y", 453 * scaleY),
        "logic", Map(
            "low_20", "match",
            "low_30", "match",
            "low_60", "match",
            "high_30", "match",
            "high_60", "unlimited"),
        "key_press_ms", Map("20", 10, "30", 5, "60", 4),
        "transition_ms", Map("20", 70, "30", 55, "60", 45),
        "state", Map("fps", 20, "physics", "low", "logic", "match"),
        "overlay", Map(
            "enabled", 1,
            "x", 20,
            "y", A_ScreenHeight/4,
            "opacity", 210,
            "font", "Consolas",
            "font_size", 12,
            "text_color", "FFFFFF",
            "background", "101010")
    )
}

; Fill in missing keys / fix wrong types using the defaults
MergeDefaults(def, user) {
    for k, dv in def {
        if !user.Has(k) {
            user[k] := dv
        } else if (dv is Map) {
            if (user[k] is Map)
                MergeDefaults(dv, user[k])
            else
                user[k] := dv
        } else if ((dv is Number) != (user[k] is Number)) {
            user[k] := dv
        }
    }
}

SaveConfigMap(c) {
    global CONFIG_PATH
    f := FileOpen(CONFIG_PATH, "w", "UTF-8-RAW")
    f.Write(Json.Dump(c) "`n")
    f.Close()
}

LoadConfig() {
    global CONFIG_PATH
    def := DefaultConfig()

    ; Missing file -> create it with default values
    if !FileExist(CONFIG_PATH) {
        SaveConfigMap(def)
        return def
    }

    try {
        user := Json.Parse(FileRead(CONFIG_PATH, "UTF-8"))
        if !(user is Map)
            throw Error("The top level must be a JSON object")
    } catch as err {
        try FileMove(CONFIG_PATH, CONFIG_PATH ".bad", true)
        SaveConfigMap(def)
        MsgBox("Could not read flying_script.json (" err.Message ").`n`n"
            . "The old file was kept as flying_script.json.bad and a fresh default config was created.",
            "Flying script", "Icon!")
        return def
    }

    MergeDefaults(def, user)
    return user
}

Clamp(v, lo, hi) {
    return Max(lo, Min(hi, v))
}


cfg := LoadConfig()

; --- sanitize the remembered state ---------------------------------
st := cfg["state"]
st["physics"] := StrLower(st["physics"])
st["logic"] := StrLower(st["logic"])
if !(st["fps"] = 20 || st["fps"] = 30 || st["fps"] = 60)
    st["fps"] := 20
if !(st["physics"] = "low" || st["physics"] = "high")
    st["physics"] := "low"
if !(st["logic"] = "match" || st["logic"] = "unlimited")
    st["logic"] := "match"

lg := cfg["logic"]
for k in ["low_20", "low_30", "low_60", "high_30", "high_60"] {
    lg[k] := StrLower(lg[k])
    if !(lg[k] = "match" || lg[k] = "unlimited")
        lg[k] := "unlimited"
}

; --- settings -------------------------------------------------------
RANGE_MIN := cfg["range_min"]
RANGE_MAX := cfg["range_max"]
RANGE_STEP := cfg["range_step"]
RANGE := Clamp(cfg["range"], RANGE_MIN, RANGE_MAX)
SAFETY := cfg["safety"]
R_limit := cfg["r_limit"]
TIMER_MS := cfg["timer_ms"]

low_20 := lg["low_20"]
low_30 := lg["low_30"]
low_60 := lg["low_60"]
high_30 := lg["high_30"]
high_60 := lg["high_60"]

mn := cfg["menu"]
MENU_ESCAPE_Y := mn["escape_y"]
PHY_LOW_X := mn["phy_low_x"]
PHY_HIGH_X := mn["phy_high_x"]
PHY_MENU_Y := mn["phy_menu_y"]
FPS_MENU_Y := mn["fps_menu_y"]
LOGIC_MENU_Y := mn["logic_menu_y"]

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

keyMs := cfg["key_press_ms"]
transMs := cfg["transition_ms"]

current_fps := st["fps"]
current_phy := st["physics"]
current_logic := st["logic"]

; --- overlay ---------------------------------------------------------
ov := 0
ovStatus := 0
ovInfo := 0
ovVisible := false
ovLastStatus := ""

CreateOverlay() {
    global ov, ovStatus, ovInfo, ovVisible, cfg
    o := cfg["overlay"]

    ; Click-through (E0x20), never takes focus (E0x08000000), always on top
    ov := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 -DPIScale")
    ov.MarginX := 20
    ov.MarginY := 6
    ov.BackColor := o["background"]
    ov.SetFont("s" o["font_size"] " w700 c" o["text_color"], o["font"])
    ovStatus := ov.AddText("w300", "STOPPED")
    ov.SetFont("s" o["font_size"] " w400 c" o["text_color"], o["font"])
    ovInfo := ov.AddText("w300 y+2 r2", "")

    UpdateOverlay()
    if o["enabled"]
        ShowOverlay()
}

ShowOverlay() {
    global ov, ovVisible, cfg
    o := cfg["overlay"]

    ; Size the window while hidden so we know its width
    ov.Show("Hide AutoSize")
    ov.GetPos(, , &w)

    ; "x" is now the gap from the RIGHT edge of the screen, "y" the gap from the top
    ov.Show("x" (A_ScreenWidth - w - o["x"]) " y" o["y"] " NoActivate")
    WinSetTransparent(Clamp(o["opacity"], 0, 255), ov)
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
    cfg["state"]["fps"] := current_fps
    cfg["state"]["physics"] := current_phy
    cfg["state"]["logic"] := current_logic
    cfg["overlay"]["enabled"] := ovVisible ? 1 : 0
    try SaveConfigMap(cfg)
}

; --- configurable hotkeys -------------------------------------------
RegisterHotkey(keyName, fn) {
    try {
        Hotkey(keyName, fn, "On")
    } catch as e {
        MsgBox("Invalid hotkey '" keyName "' in flying_script.json:`n" e.Message, "Flying script", "Icon!")
    }
}

hk := cfg["hotkeys"]
RegisterHotkey(hk["start"], StartMoving)
RegisterHotkey(hk["stop"], StopMoving)
RegisterHotkey(hk["overlay"], ToggleOverlay)


; =====================================================================
;  Core logic (unchanged behaviour)
; =====================================================================
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
        R_released += 1
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
;  Start / stop (default F1 / F2, configurable in the JSON)
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
;  FPS / physics switching
; =====================================================================
*+F:: {
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

*+R:: {
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

*+E:: {
    global State, high_30

    if (State.moving && !State.x_pressed && !State.busy) {
        State.busy := true
        Change_Fps("high", 30, high_30)
    }
}

*+Q:: {
    global State, low_60

    if (State.moving && !State.x_pressed && !State.busy) {
        State.busy := true
        Change_Fps("low", 60, low_60)
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
