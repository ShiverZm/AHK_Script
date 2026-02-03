#Requires AutoHotkey v2.0

; ============================================================================
; 自动化操作GUI - 按键定时执行工具
; ============================================================================
; 功能：
; 1. 添加按键操作和间隔时间
; 2. 统一执行所有操作
; 3. 可以暂停、继续、停止执行
; ============================================================================

; 检查并请求管理员权限
if (!A_IsAdmin) {
    try {
        ; 请求管理员权限重新运行脚本
        Run('*RunAs "' . A_ScriptFullPath . '"', , , &PID)
        ExitApp()
    } catch as e {
        ; 如果用户拒绝了权限提升请求，显示提示信息
        MsgBox("此程序需要管理员权限才能正常运行。`n`n请右键点击脚本文件，选择'以管理员身份运行'。", "需要管理员权限", "Icon!")
        ExitApp()
    }
}

; 全局变量
global actionList := []  ; 存储操作列表
global isRunning := false  ; 是否正在执行
global timerID := 0  ; 定时器ID
global isLoopMode := false  ; 是否循环执行
global selectedWindowHwnd := 0  ; 选中的窗口句柄
global selectedWindowTitle := ""  ; 选中的窗口标题
global startTime := 0  ; 开始执行的时间戳（毫秒）
global isWindowHidden := false  ; 窗口是否隐藏

; 创建GUI窗口
global MyGui := Gui("+Resize", "自动化操作控制面板")
MyGui.SetFont("s10", "Microsoft YaHei UI")

; 按键输入区域
MyGui.AddText("Section w300", "按键名称：")
keyInput := MyGui.AddEdit("xs y+5 w220", "")
keyInput.ToolTip := "输入要按的键`n示例：`na, Enter, Space, Tab`nCtrl+c, Alt+F4, Shift+a`nF1, F2, Up, Down, Left, Right"

selectKeyBtn := MyGui.AddButton("x+5 yp w75", "选择按键")
selectKeyBtn.OnEvent("Click", ShowKeySelector)

MyGui.AddText("xs y+10 w300", "间隔时间（毫秒）：")
intervalInput := MyGui.AddEdit("xs y+5 w300", "1000")
intervalInput.ToolTip := "输入执行间隔时间（毫秒），例如：1000 = 1秒"

addBtn := MyGui.AddButton("xs y+10 w145", "添加操作")
deleteBtn := MyGui.AddButton("x+10 yp w145", "删除选中")

; 操作列表区域
MyGui.AddText("xs y+20 w300", "操作列表：")
actionListView := MyGui.AddListView("xs y+5 w300 h200", ["按键", "间隔(ms)"])
actionListView.ModifyCol(1, 150)
actionListView.ModifyCol(2, 120)

; 执行设置区域
loopCheckbox := MyGui.AddCheckbox("xs y+5 w150", "循环执行")
loopCheckbox.ToolTip := "勾选后，执行完所有操作后自动重新开始"

; 窗口选择区域
MyGui.AddText("xs y+10 w300", "目标窗口：")
windowSelectBtn := MyGui.AddButton("xs y+5 w100", "选择窗口")
windowSelectBtn.OnEvent("Click", SelectWindow)
windowClearBtn := MyGui.AddButton("x+5 yp w100", "清除选择")
windowClearBtn.OnEvent("Click", ClearWindowSelection)
windowInfoText := MyGui.AddText("xs y+5 w300", "未选择窗口（将发送到当前活动窗口）")
windowInfoText.SetFont("cGray")

; 控制按钮区域
startBtn := MyGui.AddButton("xs y+10 w70", "开始执行")
pauseBtn := MyGui.AddButton("x+5 yp w70", "暂停")
stopBtn := MyGui.AddButton("x+5 yp w70", "停止")
clearBtn := MyGui.AddButton("x+5 yp w70", "清空")

; 导入导出按钮
importBtn := MyGui.AddButton("xs y+10 w70", "导入")
exportBtn := MyGui.AddButton("x+5 yp w70", "导出")

; 状态显示
statusText := MyGui.AddText("xs y+10 w300", "状态：未运行")
statusText.SetFont("cBlue")

; 右侧日志区域
MyGui.AddText("x+20 ys w350", "执行日志：")
logDisplay := MyGui.AddEdit("xp y+5 w350 h400 ReadOnly Multi", "")
logDisplay.SetFont("s9", "Consolas")

; 清空日志按钮
clearLogBtn := MyGui.AddButton("xp y+5 w100", "清空日志")
clearLogBtn.OnEvent("Click", ClearLog)

; 按钮事件绑定
addBtn.OnEvent("Click", AddAction)
deleteBtn.OnEvent("Click", DeleteAction)
startBtn.OnEvent("Click", StartExecution)
pauseBtn.OnEvent("Click", PauseExecution)
stopBtn.OnEvent("Click", StopExecution)
clearBtn.OnEvent("Click", ClearList)
importBtn.OnEvent("Click", ImportActions)
exportBtn.OnEvent("Click", ExportActions)
clearLogBtn.OnEvent("Click", ClearLog)

; 双击列表项编辑
actionListView.OnEvent("DoubleClick", EditAction)

; 窗口关闭事件
MyGui.OnEvent("Close", GuiClose)

; 显示窗口（调整大小以适应左右布局：左侧320px + 右侧350px + 间距）
MyGui.Show("w690 h700")

; 注册全局热键
Hotkey("^F1", StartExecution, "On")  ; Ctrl+F1: 开始执行
Hotkey("^F2", PauseExecution, "On")  ; Ctrl+F2: 暂停执行
Hotkey("^F3", StopExecution, "On")    ; Ctrl+F3: 停止执行
Hotkey("^F4", ToggleWindowVisibility, "On")  ; Ctrl+F4: 切换窗口显示/隐藏
Hotkey("^Esc", QuitApp, "On")  ; Ctrl+Esc: 退出程序

; 添加初始日志提示
Sleep(100)  ; 等待GUI完全显示
AddLog("程序已启动")
AddLog("快捷键：Ctrl+F1=开始执行, Ctrl+F2=暂停, Ctrl+F3=停止, Ctrl+F4=显示/隐藏窗口, Ctrl+Esc=退出程序")

; 退出程序函数
QuitApp(*) {
    Hotkey("^F1", "Off")
    Hotkey("^F2", "Off")
    Hotkey("^F3", "Off")
    Hotkey("^F4", "Off")
    Hotkey("^Esc", "Off")
    ExitApp()
}

; GUI关闭时取消热键注册
GuiClose(*) {
    QuitApp()
}

; 切换窗口显示/隐藏
ToggleWindowVisibility(*) {
    global MyGui, isWindowHidden
    try {
        if (!IsSet(MyGui) || !MyGui) {
            return
        }
        
        ; 检查窗口是否存在
        if (WinExist("ahk_id " . MyGui.Hwnd)) {
            ; 窗口存在，检查是否可见
            ; 使用WinGetMinMax检查窗口状态：1=最大化, 0=正常, -1=最小化
            minMaxState := WinGetMinMax("ahk_id " . MyGui.Hwnd)
            
            ; 检查窗口是否可见（使用WinGetStyle检查WS_VISIBLE标志）
            ; WS_VISIBLE = 0x10000000
            style := WinGetStyle("ahk_id " . MyGui.Hwnd)
            isVisible := (style & 0x10000000) != 0
            
            if (!isVisible || minMaxState == -1) {
                ; 窗口被隐藏或最小化，显示它
                MyGui.Show()
                if (minMaxState == -1) {
                    MyGui.Restore()
                }
                WinActivate("ahk_id " . MyGui.Hwnd)
                isWindowHidden := false
                AddLog("窗口已显示")
            } else {
                ; 窗口正常显示，隐藏它
                MyGui.Hide()
                isWindowHidden := true
                AddLog("窗口已隐藏到托盘")
            }
        } else {
            ; 窗口不存在或被隐藏，显示它
            MyGui.Show()
            WinActivate("ahk_id " . MyGui.Hwnd)
            isWindowHidden := false
            AddLog("窗口已显示")
        }
    } catch {
        ; 忽略错误
    }
}

; ============================================================================
; 函数定义
; ============================================================================

; 最佳按键发送函数（使用窗口句柄）
BestSendKey(Key, WindowHwnd, Method := 6) {
    ; Method 1: keybd_event (需要激活窗口)
    ; Method 2: SendInput (模拟物理输入，需要激活窗口)
    ; Method 3: SendPlay (回放模式，需要激活窗口)
    ; Method 4: PostMessage (发送Windows消息，不需要激活)
    ; Method 5: SendMessage (发送Windows消息并等待，不需要激活)
    ; Method 6: ControlSend (发送到控件，不需要激活，最可靠)
    
    if (!WindowHwnd || WindowHwnd == 0) {
        ; 如果没有窗口句柄，使用普通Send
        if (Method = 2) {
            SendInput(Key)
        } else if (Method = 3) {
            SendPlay(Key)
        } else {
            Send(Key)
        }
        return true
    }
    
    ; 检查窗口是否存在
    if (!WinExist("ahk_id " . WindowHwnd)) {
        return false
    }
    
    if (Method = 1) {
        ; Method 1: DllCall keybd_event (activate window first)
        WinActivate("ahk_id " . WindowHwnd)
        Sleep(100)
        ; 对于通用按键，使用SendInput
        SendInput(Key)
        Sleep(100)
    }
    else if (Method = 2) {
        ; Method 2: SendInput (simulate physical input, activate window)
        WinActivate("ahk_id " . WindowHwnd)
        Sleep(100)
        SendInput(Key)
        Sleep(100)
    }
    else if (Method = 3) {
        ; Method 3: SendPlay (playback mode, activate window)
        WinActivate("ahk_id " . WindowHwnd)
        Sleep(50)
        SendPlay(Key)
        Sleep(100)
    }
    else if (Method = 4) {
        ; Method 4: PostMessage (send Windows message, no activate needed)
        ; WM_KEYDOWN = 0x0100, WM_KEYUP = 0x0101
        ; 对于通用按键，使用ControlSend更可靠
        ; PostMessage主要用于特定按键（如Left/Right）
        ControlSend(Key, , "ahk_id " . WindowHwnd)
        Sleep(100)
    }
    else if (Method = 5) {
        ; Method 5: SendMessage (send Windows message and wait, no activate needed)
        ; 对于通用按键，使用ControlSend更可靠
        ControlSend(Key, , "ahk_id " . WindowHwnd)
        Sleep(100)
    }
    else if (Method = 6) {
        ; Method 6: ControlSend (send to control, no activate needed, most reliable)
        ControlSend(Key, , "ahk_id " . WindowHwnd)
        Sleep(100)
    }
    else {
        ; 默认使用ControlSend
        ControlSend(Key, , "ahk_id " . WindowHwnd)
        Sleep(100)
    }
    
    return true
}

; 添加操作
AddAction(*) {
    global actionList
    key := Trim(keyInput.Value)
    interval := Trim(intervalInput.Value)
    
    if (key == "") {
        MsgBox("请输入按键名称！", "提示", "Icon!")
        return
    }
    
    if (!IsInteger(interval) || interval < 0) {
        MsgBox("间隔时间必须是大于等于0的整数！", "提示", "Icon!")
        return
    }
    
    ; 添加到列表（添加lastExecuteTime字段，初始为-1表示未执行过）
    actionList.Push({key: key, interval: Integer(interval), lastExecuteTime: -1})
    
    ; 更新ListView
    actionListView.Add("", key, interval)
    
    ; 清空输入框
    keyInput.Value := ""
    intervalInput.Value := "1000"
    
    AddLog("添加操作: " . key . " (间隔: " . interval . "ms)")
    UpdateStatus("已添加操作：" . key . " (间隔：" . interval . "ms)")
}

; 删除操作
DeleteAction(*) {
    global actionList, isRunning
    selectedRow := actionListView.GetNext()
    if (selectedRow == 0) {
        MsgBox("请先选择要删除的操作！", "提示", "Icon!")
        return
    }
    
    if (isRunning) {
        MsgBox("执行中无法删除操作，请先停止执行！", "提示", "Icon!")
        return
    }
    
    ; 从列表中删除
    deletedKey := actionList[selectedRow].key
    actionList.RemoveAt(selectedRow)
    actionListView.Delete(selectedRow)
    
    AddLog("删除操作: " . deletedKey)
    UpdateStatus("已删除操作")
}

; 编辑操作（双击）
EditAction(LV, Row) {
    global actionList, isRunning
    if (isRunning) {
        MsgBox("执行中无法编辑操作，请先停止执行！", "提示", "Icon!")
        return
    }
    
    if (Row == 0)
        return
    
    ; 获取当前值
    key := actionList[Row].key
    interval := actionList[Row].interval
    
    ; 创建编辑对话框
    EditGui := Gui("+Owner" . MyGui.Hwnd, "编辑操作")
    EditGui.SetFont("s10", "Microsoft YaHei UI")
    
    EditGui.AddText("Section w200", "按键名称：")
    editKeyInput := EditGui.AddEdit("xs y+5 w200", key)
    
    EditGui.AddText("xs y+10 w200", "间隔时间（毫秒）：")
    editIntervalInput := EditGui.AddEdit("xs y+5 w200", interval)
    
    saveBtn := EditGui.AddButton("xs y+10 w80", "保存")
    cancelBtn := EditGui.AddButton("x+5 yp w80", "取消")
    
    saveBtn.OnEvent("Click", SaveEdit)
    cancelBtn.OnEvent("Click", (*) => EditGui.Destroy())
    
    EditGui.Show()
    
    SaveEdit(*) {
        newKey := Trim(editKeyInput.Value)
        newInterval := Trim(editIntervalInput.Value)
        
        if (newKey == "") {
            MsgBox("请输入按键名称！", "提示", "Icon!")
            return
        }
        
        if (!IsInteger(newInterval) || newInterval < 0) {
            MsgBox("间隔时间必须是大于等于0的整数！", "提示", "Icon!")
            return
        }
        
        ; 更新列表（保留lastExecuteTime字段）
        oldKey := actionList[Row].key
        oldLastExecuteTime := actionList[Row].lastExecuteTime
        actionList[Row] := {key: newKey, interval: Integer(newInterval), lastExecuteTime: oldLastExecuteTime}
        actionListView.Modify(Row, "", newKey, newInterval)
        
        AddLog("更新操作: " . oldKey . " -> " . newKey . " (间隔: " . newInterval . "ms)")
        EditGui.Destroy()
        UpdateStatus("已更新操作")
    }
}

; 开始执行
StartExecution(*) {
    global actionList, isRunning, isLoopMode, startTime
    global loopCheckbox, startBtn, pauseBtn, stopBtn, addBtn, deleteBtn, clearBtn
    
    if (actionList.Length == 0) {
        MsgBox("请先添加操作！", "提示", "Icon!")
        return
    }
    
    ; 检查是否正在执行（确保 isRunning 已初始化）
    try {
        if (isRunning) {
            MsgBox("已经在执行中！", "提示", "Icon!")
            return
        }
    } catch {
        isRunning := false
    }
    
    try {
        if (IsSet(loopCheckbox) && loopCheckbox) {
            isLoopMode := loopCheckbox.Value
        } else {
            isLoopMode := false
        }
    } catch {
        isLoopMode := false
    }
    
    ; 如果是继续执行（从暂停状态恢复），调整startTime
    ; 检查是否有操作未执行过，如果有，需要更新startTime
    hasUnExecuted := false
    for i, action in actionList {
        if (action.lastExecuteTime == -1) {
            hasUnExecuted := true
            break
        }
    }
    
    ; 如果有未执行的操作，更新startTime为当前时间
    if (hasUnExecuted) {
        ; 初始化所有操作的lastExecuteTime为-1（表示未执行过）
        for i, action in actionList {
            action.lastExecuteTime := -1
        }
        ; 记录开始执行时间（毫秒）
        startTime := A_TickCount
    }
    
    isRunning := true
    
    ; 更新按钮状态
    try {
        if (IsSet(startBtn) && startBtn) {
            startBtn.Enabled := false
        }
        if (IsSet(pauseBtn) && pauseBtn) {
            pauseBtn.Enabled := true
        }
        if (IsSet(stopBtn) && stopBtn) {
            stopBtn.Enabled := true
        }
        if (IsSet(addBtn) && addBtn) {
            addBtn.Enabled := false
        }
        if (IsSet(deleteBtn) && deleteBtn) {
            deleteBtn.Enabled := false
        }
        if (IsSet(clearBtn) && clearBtn) {
            clearBtn.Enabled := false
        }
        if (IsSet(loopCheckbox) && loopCheckbox) {
            loopCheckbox.Enabled := false
        }
    } catch {
        ; GUI可能已关闭，忽略错误
    }
    
    ; 记录开始执行日志
    loopInfo := isLoopMode ? " [循环模式]" : ""
    if (hasUnExecuted) {
        AddLog("========== 开始执行 ==========")
        AddLog("操作总数：" . actionList.Length . " 个" . loopInfo)
        AddLog("执行模式：基于间隔时间执行（每秒检查一次）")
    } else {
        AddLog("========== 继续执行 ==========")
    }
    
    UpdateStatus("正在执行...")
    
    ; 启动1秒计时器，每秒检查一次所有操作
    SetTimer(TimerCheckActions, 1000)
}

; 计时器检查函数（每秒执行一次）
TimerCheckActions() {
    global actionList, isRunning, isLoopMode, startTime
    global selectedWindowHwnd, selectedWindowTitle, windowInfoText
    global actionListView
    
    if (!isRunning) {
        return
    }
    
    ; 获取当前时间（毫秒）
    currentTime := A_TickCount
    
    ; 遍历所有操作，检查是否到了执行时间
    for i, action in actionList {
        ; 判断是否需要执行
        shouldExecute := false
        
        if (action.lastExecuteTime == -1) {
            ; 如果从未执行过，检查是否到了第一次执行的时间
            ; 计算从开始执行到现在经过的时间（毫秒）
            elapsedTime := currentTime - startTime
            
            ; 如果间隔为0，立即执行；否则等待间隔时间
            if (action.interval == 0) {
                shouldExecute := true
            } else if (elapsedTime >= action.interval) {
                shouldExecute := true
            }
        } else {
            ; 如果已经执行过，检查是否到了下次执行的时间
            timeSinceLastExecute := currentTime - action.lastExecuteTime
            if (timeSinceLastExecute >= action.interval) {
                shouldExecute := true
            }
        }
        
        ; 如果需要执行
        if (shouldExecute) {
            ; 高亮当前执行的操作
            try {
                if (IsSet(actionListView) && actionListView) {
                    actionListView.Modify(i, "Select")
                }
            } catch {
                ; GUI可能已关闭，忽略错误
            }
            
            ; 执行按键操作
            try {
                keyStr := Trim(action.key)
                
                ; 转换常见的组合键格式（支持 Ctrl、Alt、Shift、Win）
                keyStr := StrReplace(keyStr, "Ctrl+", "^")
                keyStr := StrReplace(keyStr, "Alt+", "!")
                keyStr := StrReplace(keyStr, "Shift+", "+")
                keyStr := StrReplace(keyStr, "Win+", "#")
                keyStr := StrReplace(keyStr, "ctrl+", "^")
                keyStr := StrReplace(keyStr, "alt+", "!")
                keyStr := StrReplace(keyStr, "shift+", "+")
                keyStr := StrReplace(keyStr, "win+", "#")
                
                ; 判断是否需要大括号包裹
                formattedKey := ""
                if (InStr(keyStr, "^") || InStr(keyStr, "!") || InStr(keyStr, "#") || InStr(keyStr, "{") || InStr(keyStr, "}")) {
                    formattedKey := keyStr
                } else {
                    formattedKey := "{" . keyStr . "}"
                }
                
                ; 如果选择了窗口，向指定窗口发送按键；否则发送到当前活动窗口
                sendTarget := ""
                if (selectedWindowHwnd != 0) {
                    if (WinExist("ahk_id " . selectedWindowHwnd)) {
                        BestSendKey(formattedKey, selectedWindowHwnd)
                        sendTarget := " [发送到: " . selectedWindowTitle . "]"
                    } else {
                        AddLog("警告：选中的窗口已关闭，已清除窗口选择")
                        selectedWindowHwnd := 0
                        selectedWindowTitle := ""
                        try {
                            global MyGui
                            ; 检查 GUI 窗口是否存在
                            if (IsSet(MyGui) && MyGui) {
                                try {
                                    if (WinExist("ahk_id " . MyGui.Hwnd)) {
                                        if (IsSet(windowInfoText) && windowInfoText) {
                                            windowInfoText.Value := "未选择窗口（将发送到当前活动窗口）"
                                            windowInfoText.SetFont("cGray")
                                        }
                                    }
                                } catch {
                                    ; GUI窗口可能已关闭，忽略错误
                                }
                            }
                        } catch {
                            ; GUI可能已关闭，忽略错误
                        }
                        Send(formattedKey)
                        sendTarget := " [发送到当前活动窗口]"
                    }
                } else {
                    Send(formattedKey)
                    sendTarget := " [发送到当前活动窗口]"
                }
                
                ; 更新lastExecuteTime
                action.lastExecuteTime := currentTime
                
                ; 记录执行日志
                logMessage := "执行操作 #" . i . ": " . action.key . " (间隔: " . action.interval . "ms)" . sendTarget
                AddLog(logMessage)
                
                ; 更新状态显示
                loopInfo := isLoopMode ? " [循环模式]" : ""
                UpdateStatus("执行中：操作 #" . i . " - " . action.key . loopInfo)
            } catch as e {
                AddLog("执行错误 #" . i . ": " . e.Message)
                UpdateStatus("执行错误：" . e.Message)
            }
        }
    }
}

; 暂停执行
PauseExecution(*) {
    global isRunning, actionList
    global startBtn, pauseBtn
    if (!isRunning) {
        return
    }
    
    isRunning := false
    SetTimer(TimerCheckActions, 0)  ; 停止计时器
    
    AddLog("执行已暂停")
    
    try {
        if (IsSet(startBtn) && startBtn) {
            startBtn.Enabled := true
            startBtn.Text := "继续执行"
        }
        if (IsSet(pauseBtn) && pauseBtn) {
            pauseBtn.Enabled := false
        }
    } catch {
        ; GUI可能已关闭，忽略错误
    }
    
    UpdateStatus("已暂停（可点击'继续执行'恢复）")
}

; 停止执行
StopExecution(*) {
    global isRunning, actionList
    global startBtn, pauseBtn, stopBtn, addBtn, deleteBtn, clearBtn, loopCheckbox
    global actionListView
    isRunning := false
    
    ; 记录停止日志
    AddLog("执行已停止")
    
    ; 重置所有操作的lastExecuteTime
    for i, action in actionList {
        action.lastExecuteTime := -1
    }
    
    SetTimer(TimerCheckActions, 0)  ; 停止计时器
    
    ; 更新按钮状态
    try {
        if (IsSet(startBtn) && startBtn) {
            startBtn.Enabled := true
            startBtn.Text := "开始执行"
        }
        if (IsSet(pauseBtn) && pauseBtn) {
            pauseBtn.Enabled := true
        }
        if (IsSet(stopBtn) && stopBtn) {
            stopBtn.Enabled := false
        }
        if (IsSet(addBtn) && addBtn) {
            addBtn.Enabled := true
        }
        if (IsSet(deleteBtn) && deleteBtn) {
            deleteBtn.Enabled := true
        }
        if (IsSet(clearBtn) && clearBtn) {
            clearBtn.Enabled := true
        }
        if (IsSet(loopCheckbox) && loopCheckbox) {
            loopCheckbox.Enabled := true
        }
        ; 取消选择
        if (IsSet(actionListView) && actionListView) {
            actionListView.Modify(0, "-Select")
        }
    } catch {
        ; GUI可能已关闭，忽略错误
    }
    
    UpdateStatus("已停止")
}

; 清空列表
ClearList(*) {
    global actionList, isRunning
    if (isRunning) {
        MsgBox("执行中无法清空列表，请先停止执行！", "提示", "Icon!")
        return
    }
    
    result := MsgBox("确定要清空所有操作吗？", "确认", "YesNo Icon?")
    if (result == "Yes") {
        actionList := []
        actionListView.Delete()
        AddLog("已清空操作列表")
        UpdateStatus("已清空列表")
    }
}

; 导出操作列表
ExportActions(*) {
    global actionList, isRunning
    if (actionList.Length == 0) {
        MsgBox("操作列表为空，无法导出！", "提示", "Icon!")
        return
    }
    
    if (isRunning) {
        MsgBox("执行中无法导出，请先停止执行！", "提示", "Icon!")
        return
    }
    
    ; 打开文件保存对话框
    filePath := FileSelect("S16", , "保存操作列表", "文本文件 (*.txt)")
    if (filePath == "") {
        return  ; 用户取消了保存
    }
    
    ; 确保文件扩展名为.txt
    if (!RegExMatch(filePath, "\.txt$")) {
        filePath .= ".txt"
    }
    
    try {
        ; 打开文件进行写入
        file := FileOpen(filePath, "w", "UTF-8")
        if (!file) {
            MsgBox("无法创建文件！", "错误", "Icon!")
            return
        }
        
        ; 写入操作列表，格式：按键：间隔时间
        for i, action in actionList {
            file.WriteLine(action.key . "：" . action.interval)
        }
        
        file.Close()
        AddLog("已导出 " . actionList.Length . " 个操作到文件: " . filePath)
        MsgBox("导出成功！`n共导出 " . actionList.Length . " 个操作", "提示", "Icon!")
    } catch as e {
        MsgBox("导出失败：" . e.Message, "错误", "Icon!")
        AddLog("导出失败: " . e.Message)
    }
}

; 导入操作列表
ImportActions(*) {
    global actionList, isRunning
    if (isRunning) {
        MsgBox("执行中无法导入，请先停止执行！", "提示", "Icon!")
        return
    }
    
    ; 打开文件选择对话框
    filePath := FileSelect("1", , "选择操作列表文件", "文本文件 (*.txt)")
    if (filePath == "") {
        return  ; 用户取消了选择
    }
    
    try {
        ; 读取文件内容
        file := FileOpen(filePath, "r", "UTF-8")
        if (!file) {
            MsgBox("无法打开文件！", "错误", "Icon!")
            return
        }
        
        importedCount := 0
        skippedCount := 0
        
        ; 逐行读取
        while (!file.AtEOF) {
            line := Trim(file.ReadLine())
            
            ; 跳过空行
            if (line == "") {
                continue
            }
            
            ; 跳过注释行（以"；"开头的行）
            if (RegExMatch(line, "^；")) {
                continue
            }
            
            ; 解析格式：按键：间隔时间
            ; 支持中文冒号和英文冒号
            match := ""
            if (RegExMatch(line, "^(.+)：(.+)$", &match) || RegExMatch(line, "^(.+):(.+)$", &match)) {
                key := Trim(match[1])
                intervalStr := Trim(match[2])
                
                ; 验证间隔时间
                if (key != "" && IsInteger(intervalStr) && Integer(intervalStr) >= 0) {
                    interval := Integer(intervalStr)
                    
                    ; 添加到列表（添加lastExecuteTime字段）
                    actionList.Push({key: key, interval: interval, lastExecuteTime: -1})
                    actionListView.Add("", key, interval)
                    importedCount++
                } else {
                    skippedCount++
                }
            } else {
                skippedCount++
            }
        }
        
        file.Close()
        
        if (importedCount > 0) {
            AddLog("已导入 " . importedCount . " 个操作从文件: " . filePath)
            if (skippedCount > 0) {
                AddLog("跳过 " . skippedCount . " 行无效数据")
            }
            UpdateStatus("已导入 " . importedCount . " 个操作")
            MsgBox("导入成功！`n共导入 " . importedCount . " 个操作" . (skippedCount > 0 ? "`n跳过 " . skippedCount . " 行无效数据" : ""), "提示", "Icon!")
        } else {
            MsgBox("没有成功导入任何操作！`n请检查文件格式是否正确。`n格式应为：按键：间隔时间", "提示", "Icon!")
            AddLog("导入失败：没有有效数据")
        }
    } catch as e {
        MsgBox("导入失败：" . e.Message, "错误", "Icon!")
        AddLog("导入失败: " . e.Message)
    }
}

; 更新状态
UpdateStatus(message) {
    try {
        global statusText, MyGui
        ; 检查 GUI 窗口是否存在
        if (!IsSet(MyGui) || !MyGui) {
            return
        }
        ; 检查窗口是否仍然存在
        try {
            if (!WinExist("ahk_id " . MyGui.Hwnd)) {
                return
            }
        } catch {
            return
        }
        ; 检查控件是否存在
        if (IsSet(statusText) && statusText) {
            statusText.Value := "状态：" . message
        }
    } catch {
        ; GUI可能已关闭，忽略错误
    }
}

; 添加日志
AddLog(message) {
    try {
        global logDisplay, MyGui
        ; 检查 GUI 窗口是否存在
        if (!IsSet(MyGui) || !MyGui) {
            return
        }
        ; 检查窗口是否仍然存在
        try {
            if (!WinExist("ahk_id " . MyGui.Hwnd)) {
                return
            }
        } catch {
            return
        }
        ; 检查控件是否存在
        if (!IsSet(logDisplay) || !logDisplay) {
            return
        }
        
        ; 获取当前时间（AutoHotkey v2语法）
        currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        
        ; 添加到日志显示区域
        logText := logDisplay.Value
        if (logText != "") {
            logText .= "`r`n"
        }
        logText .= "[" . currentTime . "] " . message
        
        logDisplay.Value := logText
        
        ; 自动滚动到底部
        ; 使用SendMessage设置选择位置到末尾并滚动
        textLength := StrLen(logText)
        SendMessage(0xB1, textLength, textLength, , logDisplay)  ; EM_SETSEL - 设置选择范围
        SendMessage(0xB7, 0, 0, , logDisplay)  ; EM_SCROLLCARET - 滚动到插入符位置
    } catch {
        ; GUI可能已关闭，忽略错误
    }
}

; 清空日志
ClearLog(*) {
    logDisplay.Value := ""
    AddLog("日志已清空")
}

; 显示按键选择器
ShowKeySelector(*) {
    ; 创建按键选择对话框
    KeySelectorGui := Gui("+Owner" . MyGui.Hwnd, "选择按键")
    KeySelectorGui.SetFont("s10", "Microsoft YaHei UI")
    
    ; 按键分类
    KeySelectorGui.AddText("Section w400", "请选择按键：")
    
    ; 定义所有按键数据
    allKeysData := Map()
    allKeysData["全部"] := []
    allKeysData["普通按键"] := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "Space", "Enter", "Tab", "Esc", "Backspace", "Delete"]
    allKeysData["功能键"] := ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
    allKeysData["方向键"] := ["Up", "Down", "Left", "Right", "Home", "End", "PgUp", "PgDn"]
    allKeysData["数字键"] := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    ; 组合键模板
    modifierKeys := ["Ctrl", "Alt", "Shift", "Win"]
    comboKeys := []
    for i, mod in modifierKeys {
        comboKeys.Push(mod . "+c")
        comboKeys.Push(mod . "+v")
        comboKeys.Push(mod . "+x")
        comboKeys.Push(mod . "+z")
        comboKeys.Push(mod . "+a")
        comboKeys.Push(mod . "+s")
        comboKeys.Push(mod . "+F4")
        comboKeys.Push(mod . "+Tab")
    }
    allKeysData["组合键"] := comboKeys
    
    ; 合并所有按键到"全部"类别
    for category, keys in allKeysData {
        if (category != "全部") {
            for i, key in keys {
                allKeysData["全部"].Push(key)
            }
        }
    }
    
    ; 创建分类下拉框
    KeySelectorGui.AddText("xs y+5 w100", "按键分类：")
    categoryDropdown := KeySelectorGui.AddDDL("x+5 yp-3 w150 Choose1", ["全部", "普通按键", "功能键", "方向键", "数字键", "组合键"])
    
    ; 创建单个按键列表
    keyListView := KeySelectorGui.AddListView("xs y+10 w380 h320", ["按键名称"])
    keyListView.ModifyCol(1, 350)
    
    ; 刷新列表显示的函数
    RefreshKeyList(category) {
        ; 清空列表
        keyListView.Delete()
        
        ; 获取对应类别的按键
        keys := allKeysData[category]
        if (keys) {
            ; 添加到列表
            for i, key in keys {
                keyListView.Add("", key)
            }
        }
    }
    
    ; 下拉框改变事件处理函数
    CategoryChanged(*) {
        selectedCategory := categoryDropdown.Text
        RefreshKeyList(selectedCategory)
    }
    
    categoryDropdown.OnEvent("Change", CategoryChanged)
    
    ; 初始化显示"全部"类别
    RefreshKeyList("全部")
    
    ; 按钮区域
    insertBtn := KeySelectorGui.AddButton("xs y+10 w100", "插入到输入框")
    cancelBtn := KeySelectorGui.AddButton("x+10 yp w100", "取消")
    
    ; 插入按键到输入框
    InsertKey(LV, Row) {
        if (Row == 0) {
            MsgBox("请先选择一个按键！", "提示", "Icon!")
            return
        }
        
        key := LV.GetText(Row)
        if (key == "") {
            return
        }
        
        ; 获取当前输入框的值
        currentValue := keyInput.Value
        
        ; 如果输入框不为空，添加空格分隔
        if (currentValue != "") {
            keyInput.Value := currentValue . " " . key
        } else {
            keyInput.Value := key
        }
        
        ; 关闭对话框
        KeySelectorGui.Destroy()
        AddLog("已选择按键: " . key)
    }
    
    ; 列表双击事件
    keyListView.OnEvent("DoubleClick", InsertKey)
    
    ; 插入按钮事件处理函数
    InsertBtnClick(*) {
        selectedRow := keyListView.GetNext()
        if (selectedRow == 0) {
            MsgBox("请先选择一个按键！", "提示", "Icon!")
            return
        }
        InsertKey(keyListView, selectedRow)
    }
    
    insertBtn.OnEvent("Click", InsertBtnClick)
    
    cancelBtn.OnEvent("Click", (*) => KeySelectorGui.Destroy())
    
    ; 显示对话框
    KeySelectorGui.Show()
}

; 选择窗口
SelectWindow(*) {
    global selectedWindowHwnd, selectedWindowTitle, windowInfoText
    ; 创建提示窗口
    tipGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "选择窗口")
    tipGui.SetFont("s12 Bold", "Microsoft YaHei UI")
    tipGui.BackColor := "Yellow"
    tipText := tipGui.AddText("Center w400 h120", "将鼠标移动到目标窗口上`n然后按 F1 键确认选择`n按 ESC 键取消")
    tipGui.Show("x" . (A_ScreenWidth // 2 - 200) . " y" . (A_ScreenHeight // 2 - 60))
    
    ; 创建热键来捕获选择
    f1Pressed := false
    escPressed := false
    
    ; 注册热键（临时）
    Hotkey("F1", SelectWindowConfirm, "On")
    Hotkey("Esc", SelectWindowCancel, "On")
    
    SelectWindowConfirm(*) {
        f1Pressed := true
    }
    
    SelectWindowCancel(*) {
        escPressed := true
    }
    
    ; 等待用户操作
    while (!f1Pressed && !escPressed) {
        Sleep(50)
        ; 实时显示当前鼠标下的窗口信息
        MouseGetPos(, , &currentHwnd)
        if (currentHwnd != 0) {
            try {
                currentTitle := WinGetTitle("ahk_id " . currentHwnd)
                if (StrLen(currentTitle) > 40) {
                    currentTitle := SubStr(currentTitle, 1, 37) . "..."
                }
                tipText.Value := "将鼠标移动到目标窗口上`n然后按 F1 键确认选择`n按 ESC 键取消`n`n当前窗口: " . currentTitle
            }
        }
    }
    
    ; 取消热键
    Hotkey("F1", "Off")
    Hotkey("Esc", "Off")
    
    ; 关闭提示窗口
    tipGui.Destroy()
    
    if (escPressed) {
        AddLog("已取消窗口选择")
        return
    }
    
    ; 获取鼠标当前位置下的窗口
    MouseGetPos(, , &mouseHwnd)
    
    if (mouseHwnd == 0) {
        MsgBox("未能获取到窗口信息！", "错误", "Icon!")
        return
    }
    
    ; 获取窗口信息
    try {
        windowTitle := WinGetTitle("ahk_id " . mouseHwnd)
        
        ; 保存选中的窗口信息
        selectedWindowHwnd := mouseHwnd
        selectedWindowTitle := windowTitle
        
        ; 更新显示
        displayText := "已选择窗口：" . windowTitle
        if (StrLen(displayText) > 50) {
            displayText := SubStr(displayText, 1, 47) . "..."
        }
        try {
            global MyGui
            ; 检查 GUI 窗口是否存在
            if (IsSet(MyGui) && MyGui) {
                try {
                    if (WinExist("ahk_id " . MyGui.Hwnd)) {
                        if (IsSet(windowInfoText) && windowInfoText) {
                            windowInfoText.Value := displayText
                            windowInfoText.SetFont("cGreen")
                        }
                    }
                } catch {
                    ; GUI窗口可能已关闭，忽略错误
                }
            }
        } catch {
            ; GUI可能已关闭，忽略错误
        }
        
        AddLog("已选择窗口: " . windowTitle . " (句柄: " . mouseHwnd . ")")
        UpdateStatus("已选择目标窗口：" . windowTitle)
    } catch as e {
        MsgBox("获取窗口信息失败：" . e.Message, "错误", "Icon!")
        AddLog("选择窗口失败: " . e.Message)
    }
}

; 清除窗口选择
ClearWindowSelection(*) {
    global selectedWindowHwnd, selectedWindowTitle, windowInfoText, MyGui
    selectedWindowHwnd := 0
    selectedWindowTitle := ""
    try {
        ; 检查 GUI 窗口是否存在
        if (IsSet(MyGui) && MyGui) {
            try {
                if (WinExist("ahk_id " . MyGui.Hwnd)) {
                    if (IsSet(windowInfoText) && windowInfoText) {
                        windowInfoText.Value := "未选择窗口（将发送到当前活动窗口）"
                        windowInfoText.SetFont("cGray")
                    }
                }
            } catch {
                ; GUI窗口可能已关闭，忽略错误
            }
        }
    } catch {
        ; GUI可能已关闭，忽略错误
    }
    AddLog("已清除窗口选择")
    UpdateStatus("已清除窗口选择")
}
