; ============================================================================
; 键盘鼠标控制脚本 - 功能列表与操作简介
; ============================================================================
;
; 【功能列表】
; 1. 数字键盘控制鼠标移动（需NumLock关闭）
; 2. 数字键盘控制鼠标点击
; 3. 四级变速控制（Ctrl+1/2/3/4键）
; 4. 鼠标滚轮控制（数字键盘End/PgDn键）
; 5. 脚本启动/暂停/恢复/退出控制
;
; 【操作说明】
;
; 一、鼠标移动控制（需NumLock关闭）
;     NumpadLeft  - 鼠标向左移动
;     NumpadDown  - 鼠标向下移动
;     NumpadRight - 鼠标向右移动
;     NumpadUp    - 鼠标向上移动
;
; 二、鼠标点击控制（需NumLock关闭）
;     NumpadHome  - 鼠标左键（按下/释放）
;     NumpadPgUp  - 鼠标右键（单击）
;
; 三、速度调节（按住时生效，松开恢复默认速度2.0）
;     Ctrl+1 - 最慢速度（0.5倍）
;     Ctrl+2 - 慢速（1.0倍）
;     Ctrl+3 - 中速（4.0倍，默认2.0倍）
;     Ctrl+4 - 快速（8.0倍）
;
; 四、滚轮控制（需NumLock关闭）
;     NumpadEnd  - 滚轮向上
;     NumpadPgDn - 滚轮向下
;
; 五、脚本控制快捷键
;     Ctrl+F1  - 启动脚本（启用鼠标模式）
;     Ctrl+F2  - 暂停脚本（禁用鼠标模式）
;     Ctrl+F3  - 恢复脚本（重新启用鼠标模式）
;     Ctrl+Esc - 退出脚本
;
; 【注意事项】
; - 数字键盘控制功能仅在NumLock关闭时生效
; - 脚本启动时默认启用鼠标模式
; - 鼠标移动速度为相对移动，每10ms执行一次
;
; ============================================================================

#Requires AutoHotkey v2.0
;引入print.ahk
#Include print.ahk

; 定义全局变量
global mouseMode := true
global speed := 2.0
global moveX := 0
global moveY := 0

; 每10ms执行一次MoveMouse函数，函数定义见最下方
SetTimer MoveMouse, 10
print("启动脚本（启用鼠标模式）")

; 绑定数字键盘方向键位，控制鼠标指针的左、下、右、上移动
; 要求：mouseMode == true 且 NumLock 关闭
#HotIf mouseMode and !GetKeyState("NumLock", "T") ; 此行代码以下的键位绑定要求mouseMode == true 且 NumLock 关闭

NumLock::{
    print("NumLock 按键：", mouseMode)
}

NumpadLeft:: {  ; 左
    global moveX
    moveX := -10
    print("; 左")
}
NumpadLeft up:: {
    global moveX
    if (moveX < 0)
        moveX := 0
}

NumpadRight:: {  ; 右
    global moveX
    moveX := 10
}
NumpadRight up:: {
    global moveX
    if (moveX > 0)
        moveX := 0
}

NumpadUp:: {  ; 上
    global moveY
    moveY := -10
}
NumpadUp up:: {
    global moveY
    if (moveY < 0)
        moveY := 0
}

NumpadDown:: {  ; 下
    global moveY
    moveY := 10
}
NumpadDown up:: {
    global moveY
    if (moveY > 0)
        moveY := 0
}

; 设置四级变速，当按住Ctrl+1/2/3/4键位时会改变鼠标移动速度
; 速度以1 2 3 4递增：最慢(0.5) -> 慢速(1.0) -> 中速(4.0) -> 快速(8.0)
; 这些快捷键不需要任何条件，放在脚本控制快捷键之前
#HotIf ; 速度调节快捷键不需要任何条件
^1:: {
    global speed
    speed := 0.5
}
^1 up:: {
    global speed
    speed := 2.0
}

^2:: {
    global speed
    speed := 1.0
}
^2 up:: {
    global speed
    speed := 2.0
}

^3:: {
    global speed
    speed := 4.0
}
^3 up:: {
    global speed
    speed := 2.0
}

^4:: {
    global speed
    speed := 8.0
}
^4 up:: {
    global speed
    speed := 2.0
}

; 控制鼠标点击操作（数字键盘Home、PgUp，要求NumLock关闭）
#HotIf mouseMode and !GetKeyState("NumLock", "T")
; left click
NumpadHome:: {
    Click "Down"
}
NumpadHome up:: {
    Click "Up"
}

; right click
NumpadPgUp:: {
    Click 'R'
}

; 数字键盘End、PgDn键绑定鼠标滚轮向上/向下（要求NumLock关闭）
NumpadEnd:: {
    Click 'WheelUp'
}
NumpadPgDn:: {
    Click 'WheelDown'
}

; 脚本控制快捷键（不需要任何条件）
#HotIf ; 此行代码以下的任何键位绑定不需要任何要求
^F1:: {  ; 启动脚本
    global mouseMode
    mouseMode := true
    SetTimer MoveMouse, 10
    print("启动脚本（启用鼠标模式）")
}

^F2:: {  ; 暂停脚本
    global mouseMode
    mouseMode := false
    SetTimer MoveMouse, 0
    global moveX, moveY
    moveX := 0
    moveY := 0
    print("暂停脚本（禁用鼠标模式）")
}

^F3:: {  ; 恢复脚本
    global mouseMode
    mouseMode := true
    SetTimer MoveMouse, 10
    print("恢复脚本（重新启用鼠标模式）")
}

^Esc:: {  ; 退出脚本
    print("退出脚本")
    ExitApp
}

MoveMouse() {
    global moveX, moveY, mouseMode, speed
    if ((moveX or moveY) and mouseMode) {
        MouseMove(moveX * speed, moveY * speed, 0, "R")

        print("MoveMouse real")
    }
}
