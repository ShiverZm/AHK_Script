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

print(arr*)

{	

	for i,v in arr{

		printvalue.=(A_Index=1 ? "":",") json(v) 

	}

	if(arr.Length()=0)

	printvalue:=""

	ex := Exception("", -1)

	FileReadLine ScriptLine, %A_ScriptFullPath%, % ex.Line

	global guiexist

	global printtext

	global hEdit

	if(guiexist=""){

		guiexist:=1

		SetTimer,guishow,-0

		Sleep 100

	}

	printtext.="[" Format("{:03}",ex.line) "]| " json(printvalue) "`n"

	;printtext.=json(printvalue) "`n"

	GuiControl,print:text,printt1,%printtext%

	SendMessage, 0xB1, -2, -1,, ahk_id %hEdit% ; 将光标移动到末尾

	SendMessage, 0xB7, 0, 0, , ahk_id %hEdit% ; 滚动到末端

return

guishow:

{

	gui,print:new,,print

	gui,print:+Resize

	; gui,print:Default

	Gui,print:Font,s10 cdcdcaa, verdana

	gui,print:Color,2b2b2b

	Gui,print:Add,Edit,vprintt1 w480 h500 HwndhEdit ReadOnly,

	Gui,print:Show,w500 h515 y360,print

}

return

printGuiClose:

	ExitApp

return

printGuiSize:

GuiControl,print:move,printt1,% "w" A_GuiWidth-15 "h" A_GuiHeight-15

Return

}



json( obj ) {



	If IsObject( obj )

	{

		isarray := 0 ; an empty object could be an array... but it ain't, says I

		for key in obj

			if ( key != ++isarray )

			{

				isarray := 0

				Break

			}



		for key, val in obj

			str .= ( A_Index = 1 ? "" : "," ) ( isarray ? "" : json( key ) ":" ) json( val )



		return isarray ? "[" str "]" : "{" str "}"

	}

	else

	return obj

}