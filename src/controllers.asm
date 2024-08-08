.include	"controllers.inc"



.zeropage
buttons_up:				.RES 4	; Buttons released on this frame
buttons_down:			.RES 4	; Buttons pressed on this frame
buttons_held:			.RES 4	; Buttons currently pressed
buttons_held_new:		.RES 4	; Buffer that controller state is read into



; Constants
CONTROLLER_PORT_1		:= $4016
CONTROLLER_PORT_2		:= $4017



.code
; Read four score controller status into buttons_held_new. 
; Should be called once per graphical frame in a place where it won't conflict with DMC DMA, i.e. during vblank or during DMC IRQ handler
; Trashes A
.proc	read_four_score

strobe_controllers:
	LDA #$01
	STA CONTROLLER_PORT_1		; Initiate strobe
	STA buttons_held_new + 3	; Initialize buttons_held_new + 1 / 3 as a ring counter
	LSR							; A = 0
	STA buttons_held_new + 1
	STA CONTROLLER_PORT_1		; Halt strobe

read_loop:
	LDA CONTROLLER_PORT_1
	LSR
	ROL buttons_held_new + 2
	ROL buttons_held_new + 0

	LDA CONTROLLER_PORT_2
	LSR
	ROL buttons_held_new + 3
	ROL buttons_held_new + 1
	BCC read_loop

	RTS
.endproc

; Computes the state of buttons_held, buttons_down, and buttons_up from previous buttons_held state and buttons_held_new.
; Should be called once per logical frame.
; Trashes A, X
.proc	update_controller_state
	LDX #$03
:	LDA buttons_held, X			; buttons_down = ~buttons_held & buttons_held_new; i.e. rising edge
	EOR #$FF
	AND buttons_held_new, X
	STA buttons_down, X

	LDA buttons_held_new, X		; buttons_up = ~buttons_held_new & buttons_held; i.e. falling edge
	EOR #$FF
	AND buttons_held, X
	STA buttons_up, X

	LDA buttons_held_new, X		; Copy new button state over previous frame's state
	STA buttons_held, X

	DEX
	BPL :-

	RTS
.endproc