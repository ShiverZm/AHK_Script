/*
o------------------------------------------------------------o
|使用键盘小键盘作为鼠标                                        |
(------------------------------------------------------------)
| 作者: deguix           / 适用于 AutoHotkey 1.0.22+ 的脚本文件 |
|                    ----------------------------------------|
|                                                            |
|    本脚本是 AutoHotkey 的使用示例。它通过重新映射键盘的    |
| 小键盘按键，将其转换为鼠标。一些特性包括加速功能，可以    |
| 在长时间按住按键时增加鼠标移动速度，以及旋转功能，使      |
| 小键盘鼠标能够"转向"。例如，NumPadDown 作为 NumPadUp      |
| 使用，反之亦然。请参阅下面使用的按键列表：                |
|                                                            |
|------------------------------------------------------------|
| 按键                  | 说明                              |
|------------------------------------------------------------|
| ScrollLock (切换开启)  | 激活小键盘鼠标模式。              |
|-----------------------|------------------------------------|
| NumPad0               | 左键点击。                        |
| NumPad5               | 中键点击。                        |
| NumPadDot             | 右键点击。                        |
| NumPadDiv/NumPadMult  | X1/X2 鼠标按键点击。(Win 2k+)     |
| NumPadSub/NumPadAdd   | 向上/向下滚动鼠标滚轮。            |
|                       |                                    |
|-----------------------|------------------------------------|
| NumLock (切换关闭)    | 激活鼠标移动模式。                |
|-----------------------|------------------------------------|
| NumPadEnd/Down/PgDn/  | 鼠标移动。                        |
| /Left/Right/Home/Up/  |                                    |
| /PgUp                 |                                    |
|                       |                                    |
|-----------------------|------------------------------------|
| NumLock (切换开启)    | 激活鼠标速度调整模式。            |
|-----------------------|------------------------------------|
| NumPad7/NumPad1       | 每次按键增加/减少加速度。          |
|                       |                                    |
| NumPad8/NumPad2       | 每次按键增加/减少初始速度。        |
|                       |                                    |
| NumPad9/NumPad3       | 每次按键增加/减少最大速度。        |
|                       |                                    |
| ^NumPad7/^NumPad1     | 每次按键增加/减少滚轮加速度*。      |
|                       |                                    |
| ^NumPad8/^NumPad2     | 每次按键增加/减少滚轮初始速度*。    |
|                       |                                    |
| ^NumPad9/^NumPad3     | 每次按键增加/减少滚轮最大速度*。    |
|                       |                                    |
| NumPad4/NumPad6       | 增加/减少向右旋转角度（度）。      |
|                       | （例如 180° = 反向控制）          |
|------------------------------------------------------------|
| * = 这些选项受控制面板中调整的鼠标滚轮速度影响。如果       |
| 您没有带滚轮的鼠标，默认值为每次选项按键按下 3 +/- 行。   |
o------------------------------------------------------------o
*/

;配置部分开始

#SingleInstance force
#MaxHotkeysPerInterval 500

; 使用键盘钩子来实现小键盘热键可以防止它们干扰 ANSI 字符的生成，
; 例如 à。这是因为 AutoHotkey 通过按住 ALT 并发送一系列小键盘
; 按键来生成此类字符。钩子热键足够智能，可以忽略此类按键。
#UseHook

MouseSpeed = 1
MouseAccelerationSpeed = 1
MouseMaxSpeed = 5

;鼠标滚轮速度也在控制面板中设置。由于这会影响正常鼠标行为，
;下面这三个的实际速度是正常鼠标滚轮速度的倍数。
MouseWheelSpeed = 1
MouseWheelAccelerationSpeed = 1
MouseWheelMaxSpeed = 5

MouseRotationAngle = 0

;配置部分结束

;这是必需的，否则按键会错误地发送其自然操作。例如 NumPadDiv
;有时会向屏幕发送 "/"。
#InstallKeybdHook

Temp = 0
Temp2 = 0

MouseRotationAnglePart = %MouseRotationAngle%
;除以 45º 是因为 MouseMove 只支持整数，将鼠标旋转改为小于 45º
;的数字可能会导致奇怪的移动。
;
;例如：按下 NumPadUp 时 22.5º：
;  首先它会向上移动，直到侧向速度达到 1。
MouseRotationAnglePart /= 45

MouseCurrentAccelerationSpeed = 0
MouseCurrentSpeed = %MouseSpeed%

MouseWheelCurrentAccelerationSpeed = 0
MouseWheelCurrentSpeed = %MouseSpeed%

SetKeyDelay, -1
SetMouseDelay, -1

Hotkey, *NumPad0, ButtonLeftClick
Hotkey, *NumpadIns, ButtonLeftClickIns
Hotkey, *NumPad5, ButtonMiddleClick
Hotkey, *NumpadClear, ButtonMiddleClickClear
Hotkey, *NumPadDot, ButtonRightClick
Hotkey, *NumPadDel, ButtonRightClickDel
Hotkey, *NumPadDiv, ButtonX1Click
Hotkey, *NumPadMult, ButtonX2Click

Hotkey, *NumpadSub, ButtonWheelUp
Hotkey, *NumpadAdd, ButtonWheelDown

Hotkey, *NumPadUp, ButtonUp
Hotkey, *NumPadDown, ButtonDown
Hotkey, *NumPadLeft, ButtonLeft
Hotkey, *NumPadRight, ButtonRight
Hotkey, *NumPadHome, ButtonUpLeft
Hotkey, *NumPadEnd, ButtonUpRight
Hotkey, *NumPadPgUp, ButtonDownLeft
Hotkey, *NumPadPgDn, ButtonDownRight

Hotkey, Numpad8, ButtonSpeedUp
Hotkey, Numpad2, ButtonSpeedDown
Hotkey, Numpad7, ButtonAccelerationSpeedUp
Hotkey, Numpad1, ButtonAccelerationSpeedDown
Hotkey, Numpad9, ButtonMaxSpeedUp
Hotkey, Numpad3, ButtonMaxSpeedDown

Hotkey, Numpad6, ButtonRotationAngleUp
Hotkey, Numpad4, ButtonRotationAngleDown

Hotkey, !Numpad8, ButtonWheelSpeedUp
Hotkey, !Numpad2, ButtonWheelSpeedDown
Hotkey, !Numpad7, ButtonWheelAccelerationSpeedUp
Hotkey, !Numpad1, ButtonWheelAccelerationSpeedDown
Hotkey, !Numpad9, ButtonWheelMaxSpeedUp
Hotkey, !Numpad3, ButtonWheelMaxSpeedDown

Gosub, ~ScrollLock  ; 根据当前 ScrollLock 状态初始化。
return

;按键激活支持

~ScrollLock::
; 等待它被释放，否则在按键按下时钩子状态会被重置，这会导致
; 按键释放事件被抑制，进而阻止 ScrollLock 状态/指示灯切换：
KeyWait, ScrollLock
GetKeyState, ScrollLockState, ScrollLock, T
If ScrollLockState = D
{
    Hotkey, *NumPad0, on
    Hotkey, *NumpadIns, on
    Hotkey, *NumPad5, on
    Hotkey, *NumPadDot, on
    Hotkey, *NumPadDel, on
    Hotkey, *NumPadDiv, on
    Hotkey, *NumPadMult, on

    Hotkey, *NumpadSub, on
    Hotkey, *NumpadAdd, on

    Hotkey, *NumPadUp, on
    Hotkey, *NumPadDown, on
    Hotkey, *NumPadLeft, on
    Hotkey, *NumPadRight, on
    Hotkey, *NumPadHome, on
    Hotkey, *NumPadEnd, on
    Hotkey, *NumPadPgUp, on
    Hotkey, *NumPadPgDn, on

    Hotkey, Numpad8, on
    Hotkey, Numpad2, on
    Hotkey, Numpad7, on
    Hotkey, Numpad1, on
    Hotkey, Numpad9, on
    Hotkey, Numpad3, on

    Hotkey, Numpad6, on
    Hotkey, Numpad4, on

    Hotkey, !Numpad8, on
    Hotkey, !Numpad2, on
    Hotkey, !Numpad7, on
    Hotkey, !Numpad1, on
    Hotkey, !Numpad9, on
    Hotkey, !Numpad3, on
}
else
{
    Hotkey, *NumPad0, off
    Hotkey, *NumpadIns, off
    Hotkey, *NumPad5, off
    Hotkey, *NumPadDot, off
    Hotkey, *NumPadDel, off
    Hotkey, *NumPadDiv, off
    Hotkey, *NumPadMult, off

    Hotkey, *NumpadSub, off
    Hotkey, *NumpadAdd, off

    Hotkey, *NumPadUp, off
    Hotkey, *NumPadDown, off
    Hotkey, *NumPadLeft, off
    Hotkey, *NumPadRight, off
    Hotkey, *NumPadHome, off
    Hotkey, *NumPadEnd, off
    Hotkey, *NumPadPgUp, off
    Hotkey, *NumPadPgDn, off

    Hotkey, Numpad8, off
    Hotkey, Numpad2, off
    Hotkey, Numpad7, off
    Hotkey, Numpad1, off
    Hotkey, Numpad9, off
    Hotkey, Numpad3, off

    Hotkey, Numpad6, off
    Hotkey, Numpad4, off

    Hotkey, !Numpad8, off
    Hotkey, !Numpad2, off
    Hotkey, !Numpad7, off
    Hotkey, !Numpad1, off
    Hotkey, !Numpad9, off
    Hotkey, !Numpad3, off
}
return

;鼠标点击支持

ButtonLeftClick:
GetKeyState, already_down_state, LButton
If already_down_state = D
    return
Button2 = NumPad0
ButtonClick = Left
Goto ButtonClickStart
ButtonLeftClickIns:
GetKeyState, already_down_state, LButton
If already_down_state = D
    return
Button2 = NumPadIns
ButtonClick = Left
Goto ButtonClickStart

ButtonMiddleClick:
GetKeyState, already_down_state, MButton
If already_down_state = D
    return
Button2 = NumPad5
ButtonClick = Middle
Goto ButtonClickStart
ButtonMiddleClickClear:
GetKeyState, already_down_state, MButton
If already_down_state = D
    return
Button2 = NumPadClear
ButtonClick = Middle
Goto ButtonClickStart

ButtonRightClick:
GetKeyState, already_down_state, RButton
If already_down_state = D
    return
Button2 = NumPadDot
ButtonClick = Right
Goto ButtonClickStart
ButtonRightClickDel:
GetKeyState, already_down_state, RButton
If already_down_state = D
    return
Button2 = NumPadDel
ButtonClick = Right
Goto ButtonClickStart

ButtonX1Click:
GetKeyState, already_down_state, XButton1
If already_down_state = D
    return
Button2 = NumPadDiv
ButtonClick = X1
Goto ButtonClickStart

ButtonX2Click:
GetKeyState, already_down_state, XButton2
If already_down_state = D
    return
Button2 = NumPadMult
ButtonClick = X2
Goto ButtonClickStart

ButtonClickStart:
MouseClick, %ButtonClick%,,, 1, 0, D
SetTimer, ButtonClickEnd, 10
return

ButtonClickEnd:
GetKeyState, kclickstate, %Button2%, P
if kclickstate = D
    return

SetTimer, ButtonClickEnd, off
MouseClick, %ButtonClick%,,, 1, 0, U
return

;鼠标移动支持

ButtonSpeedUp:
MouseSpeed++
ToolTip, Mouse speed: %MouseSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonSpeedDown:
If MouseSpeed > 1
    MouseSpeed--
If MouseSpeed = 1
    ToolTip, Mouse speed: %MouseSpeed% pixel
else
    ToolTip, Mouse speed: %MouseSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonAccelerationSpeedUp:
MouseAccelerationSpeed++
ToolTip, Mouse acceleration speed: %MouseAccelerationSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonAccelerationSpeedDown:
If MouseAccelerationSpeed > 1
    MouseAccelerationSpeed--
If MouseAccelerationSpeed = 1
    ToolTip, Mouse acceleration speed: %MouseAccelerationSpeed% pixel
else
    ToolTip, Mouse acceleration speed: %MouseAccelerationSpeed% pixels
SetTimer, RemoveToolTip, 1000
return

ButtonMaxSpeedUp:
MouseMaxSpeed++
ToolTip, Mouse maximum speed: %MouseMaxSpeed% pixels
SetTimer, RemoveToolTip, 1000
return
ButtonMaxSpeedDown:
If MouseMaxSpeed > 1
    MouseMaxSpeed--
If MouseMaxSpeed = 1
    ToolTip, Mouse maximum speed: %MouseMaxSpeed% pixel
else
    ToolTip, Mouse maximum speed: %MouseMaxSpeed% pixels
SetTimer, RemoveToolTip, 1000
return

ButtonRotationAngleUp:
MouseRotationAnglePart++
If MouseRotationAnglePart >= 8
    MouseRotationAnglePart = 0
MouseRotationAngle = %MouseRotationAnglePart%
MouseRotationAngle *= 45
ToolTip, Mouse rotation angle: %MouseRotationAngle%°
SetTimer, RemoveToolTip, 1000
return
ButtonRotationAngleDown:
MouseRotationAnglePart--
If MouseRotationAnglePart < 0
    MouseRotationAnglePart = 7
MouseRotationAngle = %MouseRotationAnglePart%
MouseRotationAngle *= 45
ToolTip, Mouse rotation angle: %MouseRotationAngle%°
SetTimer, RemoveToolTip, 1000
return

ButtonUp:
ButtonDown:
ButtonLeft:
ButtonRight:
ButtonUpLeft:
ButtonUpRight:
ButtonDownLeft:
ButtonDownRight:
If Button <> 0
{
    IfNotInString, A_ThisHotkey, %Button%
    {
        MouseCurrentAccelerationSpeed = 0
        MouseCurrentSpeed = %MouseSpeed%
    }
}
StringReplace, Button, A_ThisHotkey, *

ButtonAccelerationStart:
If MouseAccelerationSpeed >= 1
{
    If MouseMaxSpeed > %MouseCurrentSpeed%
    {
        Temp = 0.001
        Temp *= %MouseAccelerationSpeed%
        MouseCurrentAccelerationSpeed += %Temp%
        MouseCurrentSpeed += %MouseCurrentAccelerationSpeed%
    }
}

;将 MouseRotationAngle 转换为按键方向的速度
{
    MouseCurrentSpeedToDirection = %MouseRotationAngle%
    MouseCurrentSpeedToDirection /= 90.0
    Temp = %MouseCurrentSpeedToDirection%

    if Temp >= 0
    {
        if Temp < 1
        {
            MouseCurrentSpeedToDirection = 1
            MouseCurrentSpeedToDirection -= %Temp%
            Goto EndMouseCurrentSpeedToDirectionCalculation
        }
    }
    if Temp >= 1
    {
        if Temp < 2
        {
            MouseCurrentSpeedToDirection = 0
            Temp -= 1
            MouseCurrentSpeedToDirection -= %Temp%
            Goto EndMouseCurrentSpeedToDirectionCalculation
        }
    }
    if Temp >= 2
    {
        if Temp < 3
        {
            MouseCurrentSpeedToDirection = -1
            Temp -= 2
            MouseCurrentSpeedToDirection += %Temp%
            Goto EndMouseCurrentSpeedToDirectionCalculation
        }
    }
    if Temp >= 3
    {
        if Temp < 4
        {
            MouseCurrentSpeedToDirection = 0
            Temp -= 3
            MouseCurrentSpeedToDirection += %Temp%
            Goto EndMouseCurrentSpeedToDirectionCalculation
        }
    }
}
EndMouseCurrentSpeedToDirectionCalculation:

;将 MouseRotationAngle 转换为向右 90 度的速度
{
    MouseCurrentSpeedToSide = %MouseRotationAngle%
    MouseCurrentSpeedToSide /= 90.0
    Temp = %MouseCurrentSpeedToSide%
    Transform, Temp, mod, %Temp%, 4

    if Temp >= 0
    {
        if Temp < 1
        {
            MouseCurrentSpeedToSide = 0
            MouseCurrentSpeedToSide += %Temp%
            Goto EndMouseCurrentSpeedToSideCalculation
        }
    }
    if Temp >= 1
    {
        if Temp < 2
        {
            MouseCurrentSpeedToSide = 1
            Temp -= 1
            MouseCurrentSpeedToSide -= %Temp%
            Goto EndMouseCurrentSpeedToSideCalculation
        }
    }
    if Temp >= 2
    {
        if Temp < 3
        {
            MouseCurrentSpeedToSide = 0
            Temp -= 2
            MouseCurrentSpeedToSide -= %Temp%
            Goto EndMouseCurrentSpeedToSideCalculation
        }
    }
    if Temp >= 3
    {
        if Temp < 4
        {
            MouseCurrentSpeedToSide = -1
            Temp -= 3
            MouseCurrentSpeedToSide += %Temp%
            Goto EndMouseCurrentSpeedToSideCalculation
        }
    }
}
EndMouseCurrentSpeedToSideCalculation:

MouseCurrentSpeedToDirection *= %MouseCurrentSpeed%
MouseCurrentSpeedToSide *= %MouseCurrentSpeed%

Temp = %MouseRotationAnglePart%
Transform, Temp, Mod, %Temp%, 2

If Button = NumPadUp
{
    if Temp = 1
    {
        MouseCurrentSpeedToSide *= 2
        MouseCurrentSpeedToDirection *= 2
    }

    MouseCurrentSpeedToDirection *= -1
    MouseMove, %MouseCurrentSpeedToSide%, %MouseCurrentSpeedToDirection%, 0, R
}
else if Button = NumPadDown
{
    if Temp = 1
    {
        MouseCurrentSpeedToSide *= 2
        MouseCurrentSpeedToDirection *= 2
    }

    MouseCurrentSpeedToSide *= -1
    MouseMove, %MouseCurrentSpeedToSide%, %MouseCurrentSpeedToDirection%, 0, R
}
else if Button = NumPadLeft
{
    if Temp = 1
    {
        MouseCurrentSpeedToSide *= 2
        MouseCurrentSpeedToDirection *= 2
    }

    MouseCurrentSpeedToSide *= -1
    MouseCurrentSpeedToDirection *= -1

    MouseMove, %MouseCurrentSpeedToDirection%, %MouseCurrentSpeedToSide%, 0, R
}
else if Button = NumPadRight
{
    if Temp = 1
    {
        MouseCurrentSpeedToSide *= 2
        MouseCurrentSpeedToDirection *= 2
    }

    MouseMove, %MouseCurrentSpeedToDirection%, %MouseCurrentSpeedToSide%, 0, R
}
else if Button = NumPadHome
{
    Temp = %MouseCurrentSpeedToDirection%
    Temp -= %MouseCurrentSpeedToSide%
    Temp *= -1
    Temp2 = %MouseCurrentSpeedToDirection%
    Temp2 += %MouseCurrentSpeedToSide%
    Temp2 *= -1
    MouseMove, %Temp%, %Temp2%, 0, R
}
else if Button = NumPadPgUp
{
    Temp = %MouseCurrentSpeedToDirection%
    Temp += %MouseCurrentSpeedToSide%
    Temp2 = %MouseCurrentSpeedToDirection%
    Temp2 -= %MouseCurrentSpeedToSide%
    Temp2 *= -1
    MouseMove, %Temp%, %Temp2%, 0, R
}
else if Button = NumPadEnd
{
    Temp = %MouseCurrentSpeedToDirection%
    Temp += %MouseCurrentSpeedToSide%
    Temp *= -1
    Temp2 = %MouseCurrentSpeedToDirection%
    Temp2 -= %MouseCurrentSpeedToSide%
    MouseMove, %Temp%, %Temp2%, 0, R
}
else if Button = NumPadPgDn
{
    Temp = %MouseCurrentSpeedToDirection%
    Temp -= %MouseCurrentSpeedToSide%
    Temp2 *= -1
    Temp2 = %MouseCurrentSpeedToDirection%
    Temp2 += %MouseCurrentSpeedToSide%
    MouseMove, %Temp%, %Temp2%, 0, R
}

SetTimer, ButtonAccelerationEnd, 10
return

ButtonAccelerationEnd:
GetKeyState, kstate, %Button%, P
if kstate = D
    Goto ButtonAccelerationStart

SetTimer, ButtonAccelerationEnd, off
MouseCurrentAccelerationSpeed = 0
MouseCurrentSpeed = %MouseSpeed%
Button = 0
return

;鼠标滚轮移动支持

ButtonWheelSpeedUp:
MouseWheelSpeed++
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
    MouseWheelSpeedMultiplier = 1
MouseWheelSpeedReal = %MouseWheelSpeed%
MouseWheelSpeedReal *= %MouseWheelSpeedMultiplier%
ToolTip, Mouse wheel speed: %MouseWheelSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return
ButtonWheelSpeedDown:
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
    MouseWheelSpeedMultiplier = 1
If MouseWheelSpeedReal > %MouseWheelSpeedMultiplier%
{
    MouseWheelSpeed--
    MouseWheelSpeedReal = %MouseWheelSpeed%
    MouseWheelSpeedReal *= %MouseWheelSpeedMultiplier%
}
If MouseWheelSpeedReal = 1
    ToolTip, Mouse wheel speed: %MouseWheelSpeedReal% line
else
    ToolTip, Mouse wheel speed: %MouseWheelSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return

ButtonWheelAccelerationSpeedUp:
MouseWheelAccelerationSpeed++
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
    MouseWheelSpeedMultiplier = 1
MouseWheelAccelerationSpeedReal = %MouseWheelAccelerationSpeed%
MouseWheelAccelerationSpeedReal *= %MouseWheelSpeedMultiplier%
ToolTip, Mouse wheel acceleration speed: %MouseWheelAccelerationSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return
ButtonWheelAccelerationSpeedDown:
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
    MouseWheelSpeedMultiplier = 1
If MouseWheelAccelerationSpeed > 1
{
    MouseWheelAccelerationSpeed--
    MouseWheelAccelerationSpeedReal = %MouseWheelAccelerationSpeed%
    MouseWheelAccelerationSpeedReal *= %MouseWheelSpeedMultiplier%
}
If MouseWheelAccelerationSpeedReal = 1
    ToolTip, Mouse wheel acceleration speed: %MouseWheelAccelerationSpeedReal% line
else
    ToolTip, Mouse wheel acceleration speed: %MouseWheelAccelerationSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return

ButtonWheelMaxSpeedUp:
MouseWheelMaxSpeed++
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
    MouseWheelSpeedMultiplier = 1
MouseWheelMaxSpeedReal = %MouseWheelMaxSpeed%
MouseWheelMaxSpeedReal *= %MouseWheelSpeedMultiplier%
ToolTip, Mouse wheel maximum speed: %MouseWheelMaxSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return
ButtonWheelMaxSpeedDown:
RegRead, MouseWheelSpeedMultiplier, HKCU, Control Panel\Desktop, WheelScrollLines
If MouseWheelSpeedMultiplier <= 0
    MouseWheelSpeedMultiplier = 1
If MouseWheelMaxSpeed > 1
{
    MouseWheelMaxSpeed--
    MouseWheelMaxSpeedReal = %MouseWheelMaxSpeed%
    MouseWheelMaxSpeedReal *= %MouseWheelSpeedMultiplier%
}
If MouseWheelMaxSpeedReal = 1
    ToolTip, Mouse wheel maximum speed: %MouseWheelMaxSpeedReal% line
else
    ToolTip, Mouse wheel maximum speed: %MouseWheelMaxSpeedReal% lines
SetTimer, RemoveToolTip, 1000
return

ButtonWheelUp:
ButtonWheelDown:

If Button <> 0
{
    If Button <> %A_ThisHotkey%
    {
        MouseWheelCurrentAccelerationSpeed = 0
        MouseWheelCurrentSpeed = %MouseWheelSpeed%
    }
}
StringReplace, Button, A_ThisHotkey, *

ButtonWheelAccelerationStart:
If MouseWheelAccelerationSpeed >= 1
{
    If MouseWheelMaxSpeed > %MouseWheelCurrentSpeed%
    {
        Temp = 0.001
        Temp *= %MouseWheelAccelerationSpeed%
        MouseWheelCurrentAccelerationSpeed += %Temp%
        MouseWheelCurrentSpeed += %MouseWheelCurrentAccelerationSpeed%
    }
}

If Button = NumPadSub
    MouseClick, wheelup,,, %MouseWheelCurrentSpeed%, 0, D
else if Button = NumPadAdd
    MouseClick, wheeldown,,, %MouseWheelCurrentSpeed%, 0, D

SetTimer, ButtonWheelAccelerationEnd, 100
return

ButtonWheelAccelerationEnd:
GetKeyState, kstate, %Button%, P
if kstate = D
    Goto ButtonWheelAccelerationStart

MouseWheelCurrentAccelerationSpeed = 0
MouseWheelCurrentSpeed = %MouseWheelSpeed%
Button = 0
return

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return