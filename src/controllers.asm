.include	"controllers.inc"
; Controller port MMIO registers
CONTROLLER_PORT_1		= $4016
CONTROLLER_PORT_2		= $4017





.zeropage
buttons_up:				.res 2	; Buttons released on this frame
buttons_down:			.res 2	; Buttons pressed on this frame
buttons_held:			.res 2	; Buttons currently pressed





.code
; Read state of two standard controllers
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, $00 - $01
.proc	read_controllers
	buttons_held_new	= $00	; And $01

strobe_controllers:
	LDA #$01
	STA CONTROLLER_PORT_1		; Initiate strobe
	STA buttons_held_new + 1	; Initialize buttons_held_new + 1 as a ring counter
	LSR							; A = 0
	STA CONTROLLER_PORT_1		; Halt strobe

read_loop:
	LDA CONTROLLER_PORT_1
	LSR
	ROL buttons_held_new + 0

	LDA CONTROLLER_PORT_2
	LSR
	ROL buttons_held_new + 1
	BCC read_loop

update_state:
	LDX #$01
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