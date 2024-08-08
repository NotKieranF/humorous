.ifndef	CONTROLLERS_INC
CONTROLLERS_INC = 1

; Read four score controller status into buttons_held_new. 
; Should be called once per graphical frame in a place where it won't conflict with DMC DMA, i.e. during vblank or during DMC IRQ handler
; Trashes A
.global		read_four_score

; Computes the state of buttons_held, buttons_down, and buttons_up from previous buttons_held state and buttons_held_new.
; Should be called once per logical frame.
; Trashes A, X
.global		update_controller_state

; Controller state arrays, each is 4 bytes
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