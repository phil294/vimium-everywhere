;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Change to 1 for a simple Alt+F mapping and to skip the window detection magic:
simple_mode = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_name = Vimium Everywhere

; Can be any color, but this value prevents a flickering until TransColor comes into effect (Linux):
win_trans_color = rgba(0`,0`,0`,0)

; Figure out the offset which an invisible, caption-less Gui window still always has.
; Expected is 0/0, but can be a few pixels.
Gui, -Caption +ToolWindow
Gui, Color, %win_trans_color%
Gui, Show, x0 y0, %app_name%
WinGet, gui_win_id, ID, %app_name%
WinGetPos, gui_win_offset_x, gui_win_offset_y, , , ahk_id %gui_win_id%
Gui, Destroy

If simple_mode = 1
{
	Hotkey, !f, Build_Show
} Else {
	Hotkey, i, Start_Input_Mode
	end_input_mode_hotkey = Escape
	Hotkey, f, Show
	Hotkey, ~LButton up, User_Input
	Hotkey, ~WheelUp up, User_Input
	Hotkey, ~WheelDown up, User_Input
	Hotkey, ~MButton up, User_Input
	Hotkey, j, Scroll_Down
	Hotkey, k, Scroll_Up
	input_mode = 0
	GoSub, Build
	keyboard_event_loop_running = 0
	GoSub, Start_Keyboard_Event_Loop
}

Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Async
Start_Keyboard_Event_Loop:
	keyboard_event_loop_stopped = 0
	SetTimer, _kbd_event_loop, 1
	Return
	_kbd_event_loop:
	SetTimer, _kbd_event_loop, OFF
	If keyboard_event_loop_running <> 0
		Return
	If keyboard_event_loop_stopped = 1
		Return
	keyboard_event_loop_running = 1
	Loop
	{
		Input, key, V L1 B, {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{CapsLock}{NumLock}{PrintScreen}
		If keyboard_event_loop_stopped = 1
		{
			keyboard_event_loop_running = 0
			Return
		}
		IfNotInString, key, f
			GoSub, User_Input
	}
Return

Stop_Keyboard_Event_Loop:
	keyboard_event_loop_stopped = 1
	Input
Return

User_Input:
	If input_mode = 0
		SetTimer, Build, 350 ; Debounce
Return

Start_Input_Mode:
	input_mode = 1
	Hotkey, %end_input_mode_hotkey%, End_Input_Mode
	ToolTip, %A_Space%i%A_Space%, 0, 0
	Suspend, On
return
End_Input_Mode:
	Suspend, Off
	input_mode = 0
	Hotkey, %end_input_mode_hotkey%, OFF
	ToolTip
	GoSub, Build
return

Build_Show:
	GoSub, Build
	GoSub, Show
Return

Build:
	SetTimer, Build, OFF
	If is_building = 1
		Return
	If is_showing = 1
		Return
	is_building = 1

	WinGet, win_id, ID, A
	Gui, Destroy
	Gui, Color, %win_trans_color%
	Gui, -Caption +ToolWindow

	ToolTip, Building..., 0, 0
	; Can be very slow in general (~1 second on Firefox).
	; Also, at-spi initialization takes several *seconds* the first time a control command runs.
	WinGet, all_controls, ControlList, ahk_id %win_id%
	WinGetPos, win_offset_x, win_offset_y, , , ahk_id %win_id%
	win_offset_x -= %gui_win_offset_x%
	win_offset_y -= %gui_win_offset_y%

	Loop, PARSE, all_controls, `n
	{
		match_controls_%A_Index% = %A_LoopField%
		ControlGetPos, x, y, , , %A_LoopField%, ahk_id %win_id%
		if x > 0
		{
			x += %win_offset_x%
			y += %win_offset_y%
			Gui, Add, Button, x%x% y%y% w10 h10, %A_Index%
		}
	}
	all_controls =

	ToolTip
	is_building = 0
	If show_queued = 1
	{
		show_queued = 0
		GoSub, Show
	}
Return

Show:
	If is_building = 1
	{
		show_queued = 1
		Return
	}
	If is_showing = 1
		Return
	is_showing = 1

	WinGet, show_win_id, ID, A
	Gui, Show, x0 y0, %app_name%
	if show_win_id <> %win_id%
	{
		Sleep, 50
		show_queued = 1
		is_showing = 0
		GoSub, Build
		Return
	}
	WinGet, gui_win_id, ID, %app_name%
	; WinActivate, ahk_id %gui_win_id%
	WinSet, TransColor, %win_trans_color%, ahk_id %gui_win_id%
	WinSet, Transparent, 230, ahk_id %gui_win_id%
	WinSet, AlwaysOnTop, ON, ahk_id %gui_win_id%

	If simple_mode <> 1
		GoSub, Stop_Keyboard_Event_Loop
	Input, selection, L1, {Escape}

	control =
	StringLeft, control, match_controls_%selection%, 10000
	If control <>
		ControlClick, %control%, ahk_id %win_id%
	Gui, Hide
	; To prevent Gui from being the active window in the next `Build` call, we need to wait
	; for `Hide` to finish. Both WinSet, Bottom and WinMinimize did not help here.
	Loop
	{
		WinGetTitle, active_win_title, A
		If active_win_title <> %app_name%
			Break
		Sleep, 100
	}
	is_showing = 0
	If simple_mode <> 1
	{
		GoSub, Start_Keyboard_Event_Loop
		If control <>
			GoSub, Build
	}
return

Scroll_Down:
	Send, {Down}
Return
Scroll_Up:
	Send, {Up}
Return