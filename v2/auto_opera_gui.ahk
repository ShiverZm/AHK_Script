#Requires AutoHotkey v2.0

; ============================================================================
; 自动化操作GUI - 按键定时执行工具
; ============================================================================
; 功能：
; 1. 添加按键操作和间隔时间
; 2. 统一执行所有操作
; 3. 可以暂停、继续、停止执行
; ============================================================================

; 全局变量
global actionList := []  ; 存储操作列表
global isRunning := false  ; 是否正在执行
global currentIndex := 0  ; 当前执行的操作索引
global timerID := 0  ; 定时器ID
global executionCount := 0  ; 当前执行次数
global maxExecutionCount := 0  ; 最大执行次数（0表示无限）
global isLoopMode := false  ; 是否循环执行

; 创建GUI窗口
MyGui := Gui("+Resize", "自动化操作控制面板")
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
MyGui.AddText("xs y+10 w300", "执行设置：")
MyGui.AddText("xs y+5 w100", "执行次数：")
executionCountInput := MyGui.AddEdit("x+5 yp-3 w80", "1")
executionCountInput.ToolTip := "设置执行次数（0或留空表示无限次）"

loopCheckbox := MyGui.AddCheckbox("xs y+10 w150", "循环执行")
loopCheckbox.ToolTip := "勾选后，执行完所有操作后自动重新开始"

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
MyGui.OnEvent("Close", (*) => ExitApp())

; 显示窗口（调整大小以适应左右布局：左侧320px + 右侧350px + 间距）
MyGui.Show("w690 h620")

; ============================================================================
; 函数定义
; ============================================================================

; 添加操作
AddAction(*) {
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
    
    ; 添加到列表
    actionList.Push({key: key, interval: Integer(interval)})
    
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
        
        ; 更新列表
        oldKey := actionList[Row].key
        actionList[Row] := {key: newKey, interval: Integer(newInterval)}
        actionListView.Modify(Row, "", newKey, newInterval)
        
        AddLog("更新操作: " . oldKey . " -> " . newKey . " (间隔: " . newInterval . "ms)")
        EditGui.Destroy()
        UpdateStatus("已更新操作")
    }
}

; 开始执行
StartExecution(*) {
    if (actionList.Length == 0) {
        MsgBox("请先添加操作！", "提示", "Icon!")
        return
    }
    
    if (isRunning) {
        MsgBox("已经在执行中！", "提示", "Icon!")
        return
    }
    
    ; 读取执行设置
    countStr := Trim(executionCountInput.Value)
    if (countStr == "" || countStr == "0") {
        maxExecutionCount := 0  ; 无限次
    } else if (IsInteger(countStr) && Integer(countStr) > 0) {
        maxExecutionCount := Integer(countStr)
    } else {
        MsgBox("执行次数必须是大于0的整数！", "提示", "Icon!")
        return
    }
    
    isLoopMode := loopCheckbox.Value
    
    ; 如果是从暂停状态继续，不重置索引和计数
    if (currentIndex == 0) {
        currentIndex := 0
        executionCount := 0
    }
    
    isRunning := true
    
    ; 更新按钮状态
    startBtn.Enabled := false
    pauseBtn.Enabled := true
    stopBtn.Enabled := true
    addBtn.Enabled := false
    deleteBtn.Enabled := false
    clearBtn.Enabled := false
    executionCountInput.Enabled := false
    loopCheckbox.Enabled := false
    
    ; 记录开始执行日志
    loopInfo := isLoopMode ? " [循环模式]" : ""
    countInfo := maxExecutionCount > 0 ? " (共" . maxExecutionCount . "轮)" : " (无限次)"
    AddLog("========== 开始执行 ==========")
    AddLog("操作总数：" . actionList.Length . " 个" . countInfo . loopInfo)
    
    UpdateStatus("正在执行...")
    
    ; 立即执行当前操作
    ExecuteNextAction()
}

; 执行下一个操作
ExecuteNextAction() {
    if (!isRunning) {
        return
    }
    
    ; 检查执行次数限制
    if (maxExecutionCount > 0 && executionCount >= maxExecutionCount) {
        StopExecution()
        UpdateStatus("已达到执行次数限制（" . maxExecutionCount . "次）！")
        return
    }
    
    ; 如果当前操作索引超出范围，需要判断是否循环
    if (currentIndex >= actionList.Length) {
        ; 完成一轮执行
        executionCount++
        
        ; 检查是否继续执行
        if (maxExecutionCount > 0 && executionCount >= maxExecutionCount) {
            StopExecution()
            UpdateStatus("已完成 " . executionCount . " 次执行！")
            return
        }
        
        ; 如果启用循环模式，重新开始
        if (isLoopMode) {
            currentIndex := 0
            AddLog("第 " . executionCount . " 轮完成，开始下一轮...")
            UpdateStatus("第 " . executionCount . " 轮完成，开始下一轮...")
            ; 继续执行第一个操作
            Sleep(100)  ; 短暂延迟
            ExecuteNextAction()
            return
        } else {
            ; 不循环，执行完毕
            StopExecution()
            AddLog("所有操作执行完毕！")
            UpdateStatus("所有操作执行完毕！")
            return
        }
    }
    
    ; 获取当前操作
    action := actionList[currentIndex + 1]
    
    ; 高亮当前执行的操作
    actionListView.Modify(currentIndex + 1, "Select")
    
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
        ; 如果已经包含特殊字符（^!+#）或大括号，直接发送
        ; 否则用大括号包裹
        if (InStr(keyStr, "^") || InStr(keyStr, "!") || InStr(keyStr, "#") || InStr(keyStr, "{") || InStr(keyStr, "}")) {
            ; 组合键或已格式化的按键，直接发送
            Send(keyStr)
        } else {
            ; 普通按键，用大括号包裹
            Send("{" . keyStr . "}")
        }
        
        ; 更新状态显示
        loopInfo := ""
        if (isLoopMode) {
            loopInfo := " [循环模式]"
        }
        countInfo := ""
        if (maxExecutionCount > 0) {
            ; 显示当前正在执行的轮次（已完成轮次+1）
            currentRound := executionCount + 1
            countInfo := " (第" . currentRound . "/" . maxExecutionCount . "轮)"
        } else if (isLoopMode) {
            countInfo := " (第" . (executionCount + 1) . "轮)"
        }
        ; 记录执行日志
        logMessage := "执行操作 " . (currentIndex + 1) . "/" . actionList.Length . ": " . action.key
        if (maxExecutionCount > 0) {
            logMessage .= " (第" . (executionCount + 1) . "/" . maxExecutionCount . "轮)"
        } else if (isLoopMode) {
            logMessage .= " (第" . (executionCount + 1) . "轮)"
        }
        AddLog(logMessage)
        
        UpdateStatus("执行中：第 " . (currentIndex + 1) . "/" . actionList.Length . " 个操作 - " . action.key . countInfo . loopInfo)
    } catch as e {
        UpdateStatus("执行错误：" . e.Message)
    }
    
    ; 移动到下一个操作
    currentIndex++
    
    ; 如果还有操作，设置定时器执行下一个
    if (currentIndex < actionList.Length) {
        nextAction := actionList[currentIndex + 1]
        timerID := SetTimer(ExecuteNextAction, -nextAction.interval)
    } else {
        ; 当前轮次的所有操作执行完毕
        executionCount++
        
        ; 检查是否达到执行次数限制
        if (maxExecutionCount > 0 && executionCount >= maxExecutionCount) {
            AddLog("========== 执行完成 ==========")
            AddLog("已完成 " . executionCount . "/" . maxExecutionCount . " 轮执行")
            StopExecution()
            UpdateStatus("已完成 " . executionCount . "/" . maxExecutionCount . " 次执行！")
            return
        }
        
        ; 如果启用循环模式，重新开始下一轮
        if (isLoopMode) {
            currentIndex := 0
            AddLog("第 " . executionCount . " 轮完成，开始下一轮...")
            UpdateStatus("第 " . executionCount . " 轮完成，开始下一轮...")
            ; 短暂延迟后继续执行第一个操作
            Sleep(100)
            ExecuteNextAction()
        } else {
            ; 不循环，执行完毕
            AddLog("========== 执行完成 ==========")
            AddLog("已完成 " . executionCount . " 轮执行")
            StopExecution()
            if (maxExecutionCount > 0) {
                UpdateStatus("已完成 " . executionCount . "/" . maxExecutionCount . " 次执行！")
            } else {
                UpdateStatus("所有操作执行完毕！")
            }
        }
    }
}

; 暂停执行
PauseExecution(*) {
    if (!isRunning) {
        return
    }
    
    isRunning := false
    SetTimer(ExecuteNextAction, 0)  ; 停止定时器
    
    AddLog("执行已暂停 (当前进度: 第" . (currentIndex) . "/" . actionList.Length . "个操作)")
    
    startBtn.Enabled := true
    startBtn.Text := "继续执行"
    pauseBtn.Enabled := false
    
    UpdateStatus("已暂停（可点击'继续执行'恢复）")
}

; 停止执行
StopExecution(*) {
    isRunning := false
    
    ; 记录停止日志
    if (currentIndex > 0 || executionCount > 0) {
        AddLog("执行已停止 (已完成: " . executionCount . "轮, 当前进度: 第" . currentIndex . "/" . actionList.Length . "个操作)")
    } else {
        AddLog("执行已停止")
    }
    
    currentIndex := 0
    executionCount := 0
    SetTimer(ExecuteNextAction, 0)  ; 停止定时器
    
    ; 更新按钮状态
    startBtn.Enabled := true
    startBtn.Text := "开始执行"
    pauseBtn.Enabled := true
    stopBtn.Enabled := false
    addBtn.Enabled := true
    deleteBtn.Enabled := true
    clearBtn.Enabled := true
    executionCountInput.Enabled := true
    loopCheckbox.Enabled := true
    
    ; 取消选择
    actionListView.Modify(0, "-Select")
    
    UpdateStatus("已停止")
}

; 清空列表
ClearList(*) {
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
            
            ; 解析格式：按键：间隔时间
            ; 支持中文冒号和英文冒号
            match := ""
            if (RegExMatch(line, "^(.+)：(.+)$", &match) || RegExMatch(line, "^(.+):(.+)$", &match)) {
                key := Trim(match[1])
                intervalStr := Trim(match[2])
                
                ; 验证间隔时间
                if (key != "" && IsInteger(intervalStr) && Integer(intervalStr) >= 0) {
                    interval := Integer(intervalStr)
                    
                    ; 添加到列表
                    actionList.Push({key: key, interval: interval})
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
    statusText.Value := "状态：" . message
}

; 添加日志
AddLog(message) {
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
