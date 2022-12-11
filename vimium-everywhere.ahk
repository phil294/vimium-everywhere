;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Change to 1 for a simple Alt+F mapping and to skip the window detection magic:
simple_mode = 0

; Comma-separated list of window classes where this script should not be active. This property is ignored in simple mode. You can determine class names using e.g. WindowSpy or xprop.
exclude_windows = VSCodium
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

/*
There are generally two operations:
	1. Build
		Runs `WinGet,, ControlList` and `ControlGetPos` for each of those controls.
		This is the performance bottleneck of this script (Linux). It can take *seconds*
		with windows with many elements, even though these commands are quite optimized.
		Also builds the Gui (invisible with visible action numbers as buttons)
	2. Show
		Shows the previously built Gui and asks the user for input, then interacts
		with the selected control, if any.

- Simple mode just runs these two one after another whenever fired via Hotkey.
- Non-simple mode continuously listens for key or mouse input or active window
	title change and then (debounced) runs `Build` on the currently active window,
	so that the `Show` Hotkey action appears to be almost instant. This approach
	is obviously much more CPU intensive, and more prone to bugs.
	Also, it adds `k` and `j` as alternative keys for `up` and `down`.
	Also, it adds an "input" mode which can be activated and deactivated with `i`
	and `Escape`, respectively. Once in input mode, all hotkeys (j, k and esp. f)
	are deactivated which is handy for typing.
*/

If simple_mode = 1
{
	; Alt-F
	Hotkey, !f, Build_Show
} Else {
	Hotkey, i, Start_Input_Mode
	end_input_mode_hotkey = Escape
	Hotkey, f, Show
	
	; Listening for mouse input:
	Hotkey, ~LButton up, User_Input
	Hotkey, ~WheelUp up, User_Input
	Hotkey, ~WheelDown up, User_Input
	Hotkey, ~MButton up, User_Input
	
	Hotkey, j, Scroll_Down
	Hotkey, k, Scroll_Up

	input_mode = 0
	keyboard_event_loop_stopped = 1
	keyboard_event_loop_running = 0
	build_pending = 0
	is_building = 0
	is_showing = 0
	is_exclude_window = 0
	show_queued = 0
	GoSub, Build
	keyboard_event_loop_running = 0
	GoSub, Start_Keyboard_Event_Loop
	GoSub, Start_Win_Title_Change_Detection_Loop
}

Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Listening for key input.
; This non-blocking input loop runs all the time in the background, except in
; link selection when it is temporarily superceded by a one-key blocking input.
Start_Keyboard_Event_Loop:
	keyboard_event_loop_stopped = 0
	; Continue as independent subthread so this does not block:
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
		; This is the official AHK way of listening for any key press:
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
	; So that should the `Show` Hotkey be fired before the next 350ms, a rebuild is preponed
	build_pending = 1
	SetTimer, Build, 250 ; Debounce
Return

; Watching window title
Start_Win_Title_Change_Detection_Loop:
	SetTimer, _title_change_detection_loop, 1
	Return
	_title_change_detection_loop:
	SetTimer, _title_change_detection_loop, OFF
	Loop
	{
		WinGetTitle, change_detection_active_win_title, A
		If change_detection_active_win_title <> %build_active_win_title%
			tooltip UIUIUI
		If change_detection_active_win_title <> %build_active_win_title%
			GoSub, User_Input
		Sleep, 300
	}
Return

Start_Input_Mode:
	input_mode = 1
	Hotkey, %end_input_mode_hotkey%, End_Input_Mode
	ToolTip, %A_Space%i%A_Space%, 0, 0
	Suspend, On
return
End_Input_Mode:
	Suspend, Off
	WinGetClass, win_class, A
	If win_class in %exclude_windows%
	{
		Suspend, On
		Return
	}
	input_mode = 0
	Hotkey, %end_input_mode_hotkey%, OFF
	ToolTip
	GoSub, Build
return

; Simple mode
Build_Show:
	GoSub, Build
	GoSub, Show
Return

Build:
	SetTimer, Build, OFF
	build_pending = 0
	If is_building = 1
		Return
	If is_showing = 1
		Return
	WinGet, build_active_win_id, ID, A
	if simple_mode <> 1
	{
		WinGetClass, win_class, ahk_id %build_active_win_id%
		If win_class in %exclude_windows%
		{
			is_exclude_window = 1
			If input_mode = 0
				; Exclude windows are excluded by simply running in input mode permanently
				GoSub, Start_Input_Mode
			Return
		}
		If is_exclude_window = 1
		{
			is_exclude_window = 0
			GoSub, End_Input_Mode
			Return
		}
		If input_mode = 1
			Return
		WinGetTitle, build_active_win_title, ahk_id %build_active_win_id%
		If build_active_win_title = %app_name%
			Return
	}
	is_building = 1
	Gui, Destroy
	Gui, Color, %win_trans_color%
	Gui, -Caption +ToolWindow

	ToolTip, Building..., 0, 0
	; Can be very slow in general (~1 second on Firefox).
	; Also, at-spi initialization can take even longer the first time a control command runs.
	WinGet, all_controls, ControlList, ahk_id %build_active_win_id%
	WinGetPos, win_offset_x, win_offset_y, , , ahk_id %build_active_win_id%
	win_offset_x -= %gui_win_offset_x%
	win_offset_y -= %gui_win_offset_y%

	control_count = 0
	available_letters = QFDSAGWERT
	decimal_factors = 1000|100|10|1 ; Exponentials of available_letters.length
	Loop, PARSE, all_controls, `n
	{
		ControlGetPos, x, y, , , %A_LoopField%, ahk_id %build_active_win_id%
		If x <= 0
			Continue
		control_count++
		If control_count > 999
			Break
		control = %A_LoopField%
		x += %win_offset_x%
		y += %win_offset_y%
		match_letters =
		rest = %control_count%
		; Transform %control_count% into %match_letters% (by index) with the weirdess
		; that is ahk legacy syntax:
		Loop, PARSE, decimal_factors, |
		{
			If control_count < %A_LoopField%
				Continue
			factor_pos = %rest%
			factor_pos /= %A_LoopField%
			factor_val = %factor_pos%
			factor_val *= %A_LoopField%
			rest -= %factor_val%
			factor_pos++
			StringMid, letter, available_letters, %factor_pos%, 1
			match_letters = %match_letters%%letter%
		}
		; Does not yet show the Gui
		Gui, Add, Button, x%x% y%y% w10 h10, %match_letters%
		match_controls_%match_letters% = %control%
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
	If build_pending = 1
	{
		show_queued = 1
		GoSub, Build
		Return
	}
	is_showing = 1

	WinGet, show_active_win_id, ID, A
	Gui, Show, x0 y0, %app_name%
	if show_active_win_id <> %build_active_win_id%
	{
		; User switched application while building, need to rebuild
		Sleep, 10
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
	selection =
	Loop
	{
		Input, key, L1, {Escape}{Space}
		If ErrorLevel = EndKey:escape
			selection =
		If ErrorLevel <> Max
			Break
		selection = %selection%%key%
		StringUpper, selection, selection
		ToolTip, %A_Space%%selection%%A_Space% ... (Press SPACE to confirm or ESCAPE to cancel), 0, 0
	}
	ToolTip

	control =
	; Array access:
	StringLeft, control, match_controls_%selection%, 10000
	If control <>
		ControlClick, %control%, ahk_id %show_active_win_id%
	Gui, Hide
	; To prevent Gui from being the active window in the next `Build` call, we need to wait
	; for `Hide` to finish. Both WinSet, Bottom and WinMinimize did not help here.
	Loop
	{
		WinGetTitle, active_win_title, A
		If active_win_title <> %app_name%
			Break
		Sleep, 50
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
	; MouseClick, WD is not the right solution as this can change window focus in Linux
	Send, {Down}
Return
Scroll_Up:
	Send, {Up}
Return