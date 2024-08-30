.scope	PLAYER
	.code
	; Initialize player state
	.proc	player_init_state
		LDA #$00
		JSR set_animation
		LDA #$02
		STA object_state, X
		RTS
	.endproc

	.proc	player_loop
		SPEED	= $2C

		LDA #$00
		STA object_x_speed, X
		STA object_y_speed, X

		LDA buttons_held
		AND #CONTROLLERS::BUTTON_DOWN
		BEQ :+
			LDA #SPEED
			STA object_y_speed, X

	:	LDA buttons_held
		AND #CONTROLLERS::BUTTON_UP
		BEQ :+
			LDA #<-SPEED
			STA object_y_speed, X

	:	LDA buttons_held
		AND #CONTROLLERS::BUTTON_LEFT
		BEQ :+
			LDA #<-SPEED
			STA object_x_speed, X

	:	LDA buttons_held
		AND #CONTROLLERS::BUTTON_RIGHT
		BEQ :+
			LDA #SPEED
			STA object_x_speed, X

	:	LDA buttons_down
		AND #CONTROLLERS::BUTTON_SELECT
		BEQ :+
			LDA object_flags, X
			EOR #%00100000
			STA object_flags, X

	:	LDA buttons_down
		AND #CONTROLLERS::BUTTON_A
		BEQ :+
			LDA #$00
			JSR set_animation

	:	LDA buttons_down
		AND #CONTROLLERS::BUTTON_B
		BEQ :+
			LDA #$02
			JSR set_animation

	:	JSR apply_speed
		RTS
	.endproc

	.rodata
	; Frame data
	.proc	player_idle_frame
		.byte	$01
		.byte	$FC, $00, $00, $FC
	.endproc

	OAM_FLIP_H = %01000000
	OAM_FLIP_V = %10000000
	.feature force_range +
bokazura_bokazura_0_data:


	.byte  31

	.byte  29,-55,$10,2
	.byte  29,-47,$17,2
	.byte  21,-48,$0f,2
	.byte  21,-40,$16,2

	.byte  21,-32,$03,2
	.byte  13,-37,$01,2
	.byte  14,-29,$02,2
	.byte  13,-21,$21,2

	.byte  13,-13,$39,2
	.byte -11,- 8,$09,2
	.byte - 3,- 8,$0a,2
	.byte   5,- 8,$0b,2

	.byte -11,-16,$07,2
	.byte - 3,-16,$08,2
	.byte   5,-16,$24,2
	.byte -11,-24,$0d,2

	.byte - 3,-24,$0e,2
	.byte   5,-24,$05,2
	.byte -13,-32,$1f,2
	.byte - 5,-32,$20,2

	.byte   3,-32,$0c,2
	.byte -14,-40,$18,2
	.byte - 6,-40,$19,2
	.byte   1,-40,$1a,3

	.byte -12,-48,$11,2
	.byte - 4,-48,$12,2
	.byte - 5,-32,$1b,3
	.byte   3,-32,$1c,3

	.byte -12,-40,$06,3
	.byte -10,-48,$04,3
	.byte  13,- 5,$22,2

bokazura_bokazura_1_data:


	.byte  31

	.byte -11,- 7,$09,2
	.byte - 3,- 7,$0a,2
	.byte   5,- 7,$0b,2
	.byte -11,-15,$07,2

	.byte - 3,-15,$08,2
	.byte   5,-15,$24,2
	.byte -11,-23,$0d,2
	.byte - 3,-23,$0e,2

	.byte   5,-23,$05,2
	.byte -13,-31,$1f,2
	.byte - 5,-31,$20,2
	.byte   3,-31,$0c,2

	.byte -14,-39,$18,2
	.byte - 6,-39,$19,2
	.byte   1,-39,$1a,3
	.byte -12,-47,$11,2

	.byte - 4,-47,$12,2
	.byte - 5,-31,$1b,3
	.byte   3,-31,$1c,3
	.byte -12,-39,$06,3

	.byte -10,-47,$04,3
	.byte  29,-50,$14,2
	.byte  29,-42,$1e,2
	.byte  21,-47,$13,2

	.byte  22,-39,$1d,2
	.byte  14,-36,$01,2
	.byte  15,-28,$02,2
	.byte  22,-31,$03,2

	.byte  13,-20,$23,2
	.byte  13,-12,$3c,2
	.byte  13,- 4,$22,2

bokazura_bokazura_2_data:


	.byte  27

	.byte -10,- 8,$09,2
	.byte - 2,- 8,$0a,2
	.byte   6,- 8,$0b,2
	.byte -10,-16,$07,2

	.byte - 2,-16,$08,2
	.byte   6,-16,$3b,2
	.byte -10,-24,$35,2
	.byte - 8,-37,$06,3

	.byte - 6,-45,$04,3
	.byte - 2,-24,$36,2
	.byte   6,-24,$05,2
	.byte -10,-32,$2e,2

	.byte - 2,-32,$2f,2
	.byte   4,-32,$0c,2
	.byte  29,-50,$14,2
	.byte  29,-42,$1e,2

	.byte  21,-47,$13,2
	.byte  22,-39,$1d,2
	.byte  14,-36,$01,2
	.byte  15,-28,$02,2

	.byte  22,-31,$03,2
	.byte  13,-20,$23,2
	.byte  14,-12,$3d,2
	.byte -10,-40,$25,2

	.byte - 2,-40,$26,2
	.byte   6,-40,$2b,2
	.byte - 4,-48,$27,2

bokazura_bokazura_3_data:


	.byte  30

	.byte  29,-55,$10,2
	.byte  29,-47,$17,2
	.byte  21,-48,$0f,2
	.byte  21,-40,$16,2

	.byte  21,-32,$03,2
	.byte  13,-37,$01,2
	.byte  14,-29,$02,2
	.byte  13,-21,$21,2

	.byte  12,-13,$3a,2
	.byte -12,- 9,$09,2
	.byte - 4,- 9,$0a,2
	.byte   4,- 9,$0b,2

	.byte -12,-17,$07,2
	.byte - 4,-17,$08,2
	.byte   4,-17,$3e,2
	.byte -12,-25,$0d,2

	.byte - 4,-25,$0e,2
	.byte   4,-25,$05,2
	.byte -14,-33,$30,2
	.byte - 6,-33,$31,2

	.byte   2,-33,$32,2
	.byte -15,-43,$06,3
	.byte -13,-51,$04,3
	.byte -17,-41,$28,2

	.byte - 9,-41,$29,2
	.byte - 7,-35,$33,3
	.byte   1,-33,$34,3
	.byte - 2,-41,$2c,3

	.byte -16,-49,$37,2
	.byte - 8,-49,$38,2

bokazura_bokazurah_ball_data:


	.byte   4

	.byte   0,- 8,$15,3
	.byte - 8,- 9,$2a,3
	.byte   1,  0,$2d,3
	.byte - 7,- 1,$15,3|OAM_FLIP_H|OAM_FLIP_V
	.feature force_range -


	; Animation data
	.proc	player_idle_animation
		.byte	$10
		.byte	$01
		.byte	$10
		.byte	$02
		.byte	$80
	.endproc

	.proc	player_test_anim_2
		.byte	9
		.byte	$04
		.byte	8
		.byte	$03
		.byte	ANIM_OPCODE::JUMP
		.byte	$00
	.endproc

	; Player state pointer table
	.proc	STATES
		INIT = (* - STATES)
		.word	player_init_state
		.word	player_loop
	.endproc

	; Player frame data pointer table
	.proc	FRAMES
		IDLE = (* - FRAMES) / 2
		.word	player_idle_frame
		.word bokazura_bokazura_0_data
		.word bokazura_bokazura_1_data
		.word bokazura_bokazura_2_data
		.word bokazura_bokazura_3_data
		.word bokazura_bokazurah_ball_data
	.endproc

	; Player animation data pointer table
	.proc	ANIMATIONS
		IDLE = (* - ANIMATIONS)
		.word	player_idle_animation
		.word	player_test_anim_2
	.endproc
.endscope