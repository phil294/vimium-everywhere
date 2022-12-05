app_name = App Name

			; initializing by gettin pos of some arbitrary frame?

f::
					AHK_X11_track_performance_start
	WinGet, win_id, ID, A

	; Can be any color, but this value prevents a flickering until TransColor comes into effect:
	trans_color = rgba(0`,0`,0`,0)
	Gui, Color, %trans_color%
	Gui, -Caption +ToolWindow
	Gui, Show, x0 y0, %app_name%
	WinGet, gui_win_id, ID, %app_name%
	WinActivate, ahk_id %gui_win_id%
	WinSet, TransColor, %trans_color%, ahk_id %gui_win_id%
	WinSet, Transparent, 230, ahk_id %gui_win_id%
	WinSet, AlwaysOnTop, ON, ahk_id %gui_win_id%
	WinGetPos, gui_win_offset_x, gui_win_offset_y, , , ahk_id %gui_win_id%

	WinGet, all_controls, ControlList, ahk_id %win_id%
	WinGetPos, win_offset_x, win_offset_y, , , ahk_id %win_id%
	win_offset_x -= %gui_win_offset_x%
	win_offset_y -= %gui_win_offset_y%
					AHK_X11_track_performance_stop
	;keywait, LCtrl, D
					AHK_X11_track_performance_start
	i = 0
												start = %a_tickcount%
	Loop, PARSE, all_controls, `n
	{
		interactive = 0
		i++
		match_controls_%i% = %A_LoopField%
		ControlGetPos, x, y, , , %A_LoopField%, ahk_id %win_id%
		x += %win_offset_x%
		y += %win_offset_y%
					;coordmode, tooltip
					;ToolTip, %A_Space%%i%%A_Space%, %x%, %y%, %i%
		Gui, Add, Button, x%x% y%y% w10 h10, %i%
		; Gui, Show
		; msgbox Gui, Add, Button, x%x% y%y%, %i%
	}
	Gui, Show
										diff = %a_tickcount%
										diff -= %start%
										echo iterating controls took %diff% ms
	controls_count = %i%
				AHK_X11_track_performance_stop
				AHK_X11_track_performance_start
	;exitapp

	Input, selection, L1, {Escape}

	control =
	StringLeft, control, match_controls_%selection%, 10000
	If control <>
		ControlClick, %control%, ahk_id %win_id%
	Gui, Destroy
	Loop
	{
		If A_Index > %controls_count%
			Break
		; ToolTip, , , , %A_Index%
		match_controls_%A_Index% =
	}
				AHK_X11_track_performance_stop
return