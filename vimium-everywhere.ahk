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
	Hotkey, f, Build_Show
Else
	GoSub, End_Input_Mode

Return

Start_Input_Mode:
	input_mode = 1
	Hotkey, i, OFF
	Hotkey, f, OFF
	Hotkey, j, OFF
	Hotkey, k, OFF
	Hotkey, Esc, End_Input_Mode
return
End_Input_Mode:
	If input_mode = 1
		Hotkey, Esc, OFF
	input_mode = 0
	GoSub, Build
	Hotkey, i, Start_Input_Mode
	Hotkey, f, Show
	Hotkey, j, Scroll_Down
	Hotkey, k, Scroll_Up
return

Build_Show:
	GoSub, Build
	GoSub, Show
Return

Build:
	WinGet, win_id, ID, A
					AHK_X11_track_performance_start
	Gui, Color, %win_trans_color%
	Gui, -Caption +ToolWindow

	; Can be very slow in general (~1 second on Firefox).
	; Also, at-spi initialization takes several *seconds* the first time a control command runs.
	WinGet, all_controls, ControlList, ahk_id %win_id%
	WinGetPos, win_offset_x, win_offset_y, , , ahk_id %win_id%
	win_offset_x -= %gui_win_offset_x%
	win_offset_y -= %gui_win_offset_y%
					AHK_X11_track_performance_stop
					AHK_X11_track_performance_start

										start = %a_tickcount%
	Loop, PARSE, all_controls, `n
	{
		i = %A_Index%
		match_controls_%i% = %A_LoopField%
		ControlGetPos, x, y, , , %A_LoopField%, ahk_id %win_id%
		x += %win_offset_x%
		y += %win_offset_y%
		Gui, Add, Button, x%x% y%y% w10 h10, %i%
	}
	controls_count = %i%
	all_controls =
										diff = %a_tickcount%
										diff -= %start%
										echo iterating controls took %diff% ms
				AHK_X11_track_performance_stop
Return

Show:
	Gui, Show, x0 y0, %app_name%
	WinGet, gui_win_id, ID, %app_name%
	; WinActivate, ahk_id %gui_win_id%
	WinSet, TransColor, %win_trans_color%, ahk_id %gui_win_id%
	WinSet, Transparent, 230, ahk_id %gui_win_id%
	WinSet, AlwaysOnTop, ON, ahk_id %gui_win_id%

	Input, selection, L1, {Escape}

				AHK_X11_track_performance_start
	control =
	StringLeft, control, match_controls_%selection%, 10000
	If control <>
		ControlClick, %control%, ahk_id %win_id%
	Gui, Hide
				AHK_X11_track_performance_stop
return

Scroll_Down:
	Send, {Down}
Return
Scroll_Up:
	Send, {Up}
Return