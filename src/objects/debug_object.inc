.include	"controllers.inc"
.include	"math.inc"
.include	"perlin.inc"


.proc	debug_object_state_table
	.word	debug_object_init_state
.endproc

.proc	debug_object_frame_table
	.word	debug_object_frame_1
.endproc



.proc	debug_object_init_state
	LDA #$00
	STA object_x_hi, X
	LDY object_x_speed, X
	LDA #$90
	LDX #$30
	JSR signed_interpolate
	LDX current_object
	CLC
	ADC #$80
	STA object_x_lo, X

	ASL object_x_lo, X
	ROL object_x_hi, X
	ASL object_x_lo, X
	ROL object_x_hi, X
	ASL object_x_lo, X
	ROL object_x_hi, X
	ASL object_x_lo, X
	ROL object_x_hi, X

	LDA buttons_held
	AND #CONTROLLERS::BUTTON_LEFT
	BEQ :+
		DEC object_x_speed, X
:	LDA buttons_held
	AND #CONTROLLERS::BUTTON_RIGHT
	BEQ :+
		INC object_x_speed, X
:

	RTS

	SPEED	= $10

	LDA buttons_held
	AND #CONTROLLERS::BUTTON_DOWN
	BEQ :+
		LDA object_y_lo, X
		CLC
		ADC #SPEED
		STA object_y_lo, X
		LDA object_y_hi, X
		ADC #$00
		STA object_y_hi, X

:	LDA buttons_held
	AND #CONTROLLERS::BUTTON_UP
	BEQ :+
		LDA object_y_lo, X
		SEC
		SBC #SPEED
		STA object_y_lo, X
		LDA object_y_hi, X
		SBC #$00
		STA object_y_hi, X

:	LDA buttons_held
	AND #CONTROLLERS::BUTTON_LEFT
	BEQ :+
		LDA object_x_lo, X
		SEC
		SBC #SPEED
		STA object_x_lo, X
		LDA object_x_hi, X
		SBC #$00
		STA object_x_hi, X

:	LDA buttons_held
	AND #CONTROLLERS::BUTTON_RIGHT
	BEQ :+
		LDA object_x_lo, X
		CLC
		ADC #SPEED
		STA object_x_lo, X
		LDA object_x_hi, X
		ADC #$00
		STA object_x_hi, X

:	LDA buttons_down
	AND #CONTROLLERS::BUTTON_SELECT
	BEQ :+
		LDA object_flags, X
		EOR #%00100000
		STA object_flags, X

:	LDA buttons_down
	AND #CONTROLLERS::BUTTON_A
	BEQ :+
		LDA object_flags, X
		EOR #%01000000
		STA object_flags, X

:	LDA buttons_down
	AND #CONTROLLERS::BUTTON_B
	BEQ :+
		LDA object_flags, X
		EOR #%10000000
		STA object_flags, X

:

	RTS
.endproc

.proc	debug_object_frame_1
	.byte	$01
	.byte	$FC, $00, $00, $FC
.endproc