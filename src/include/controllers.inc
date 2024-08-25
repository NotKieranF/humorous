.ifndef	CONTROLLERS_INC
CONTROLLERS_INC = 1

; Read state of two standard controllers
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A
.global		read_controllers

; Controller state arrays, each is 2 bytes
.globalzp	buttons_up		; Buttons released on this frame
.globalzp	buttons_down	; Buttons pressed on this frame
.globalzp	buttons_held	; Buttons currently pressed

.scope	CONTROLLERS
	BUTTON_A		= 1 << 7
	BUTTON_B		= 1 << 6
	BUTTON_SELECT	= 1 << 5
	BUTTON_START	= 1 << 4
	BUTTON_UP		= 1 << 3
	BUTTON_DOWN		= 1 << 2
	BUTTON_LEFT		= 1 << 1
	BUTTON_RIGHT	= 1 << 0
.endscope

.endif