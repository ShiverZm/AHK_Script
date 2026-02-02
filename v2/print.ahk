/*
=============================================================================
打印日志工具 (print.ahk)
=============================================================================

【功能说明】
这是一个用于 AutoHotkey v2 的日志打印工具，可以在图形界面中显示调试信息和日志输出。

【使用方法】

1. 引入文件：
   #Include print.ahk
   或
   #Include <print>

2. 调用 print() 函数输出日志：
   print("Hello, World!")
   print("变量值:", variable)
   print("数组:", array)
   print("对象:", object)
   
   支持多个参数，会自动用逗号分隔：
   print("参数1", "参数2", 123, array)

3. 显示/隐藏日志窗口：
   按 Ctrl+F10 可以切换日志窗口的显示和隐藏状态
   窗口默认是隐藏的，需要按 Ctrl+F10 才会显示

【快捷键】
   Ctrl+F10  - 显示/隐藏日志窗口

【窗口特性】
   - 窗口可以调整大小
   - 日志内容自动滚动到底部
   - 显示行号格式：[行号]| 内容
   - 点击关闭按钮会隐藏窗口（不会退出程序）

【示例代码】
   #Requires AutoHotkey v2.0
   #Include print.ahk
   
   s1 := "100"
   s2 := 100
   s3 := "autohotkey"
   s4 := {key : "nice"}
   
   print("s1:", s1)
   print("s2:", s2)
   print("s3:", s3)
   print("s4:", s4)

=============================================================================
*/
#Requires AutoHotkey v2.0
; Global variables
global guiexist := ""
global printtext := ""
global hEdit := 0
global PrintGui := ""

; Ctrl+F10 切换日志窗口显示/隐藏
^F10::TogglePrintGui()

TogglePrintGui(*) {
	global PrintGui, guiexist
	
	if (!IsObject(PrintGui) || guiexist = "") {
		; 如果窗口不存在，创建并显示
		guiexist := 1
		guishow()
		PrintGui.Show()
	} else {
		; 如果窗口存在，切换显示/隐藏
		if (WinExist("ahk_id " PrintGui.Hwnd)) {
			PrintGui.Hide()
		} else {
			PrintGui.Show()
		}
	}
}

print(arr*) {
	global guiexist, printtext, hEdit, PrintGui
	
	printvalue := ""
	
	for i, v in arr {
		printvalue .= (i = 1 ? "" : ",") json(v)
	}
	
	if (arr.Length = 0)
		printvalue := ""
	
	ex := Error("", -1)
	
	if (guiexist = "") {
		guiexist := 1
		guishow()
	}
	
	printtext .= "[" Format("{:03}", ex.Line) "]| " json(printvalue) "`n"
	
	;printtext .= json(printvalue) "`n"
	
	if (IsObject(PrintGui)) {
		PrintGui["printt1"].Value := printtext
		
		SendMessage(0xB1, -2, -1, , hEdit) ; 将光标移动到末尾
		
		SendMessage(0xB7, 0, 0, , hEdit) ; 滚动到末端
	}
}

guishow(*) {
	global PrintGui, hEdit, printtext
	
	PrintGui := Gui("+Resize", "print")
	PrintGui.BackColor := "000000"
	PrintGui.SetFont("s10 c000000", "verdana")
	
	editCtrl := PrintGui.Add("Edit", "vprintt1 w480 h500 ReadOnly")
	hEdit := editCtrl.Hwnd
	PrintGui["printt1"].Value := printtext
	
	PrintGui.OnEvent("Close", printGuiClose)
	PrintGui.OnEvent("Size", printGuiSize)
	
	; 默认不显示窗口，需要按 Ctrl+F10 来显示
	PrintGui.Show("Hide w500 h515 y360")
}

printGuiClose(*) {
	global PrintGui
	; 关闭窗口时隐藏而不是退出程序
	PrintGui.Hide()
}

printGuiSize(thisGui, MinMax, Width, Height) {
	thisGui["printt1"].Move(, , Width - 15, Height - 15)
}

json(obj) {
	If IsObject(obj) {
		isarray := 0 ; an empty object could be an array... but it ain't, says I
		str := ""
		
		for key in obj {
			if (key != ++isarray) {
				isarray := 0
				Break
			}
		}
		
		for key, val in obj {
			str .= (A_Index = 1 ? "" : ",") (isarray ? "" : json(key) ":") json(val)
		}
		
		return isarray ? "[" str "]" : "{" str "}"
	}
	else {
		return obj
	}
}
