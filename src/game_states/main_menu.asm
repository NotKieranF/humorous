.include	"main.inc"
.include	"nes.inc"
.include	"nmi.inc"
.include	"objects.inc"
.include	"controllers.inc"
.include	"perlin.inc"
.include	"graphics.inc"

.proc	main_menu_init
setup_palette:
	LDX gfx_update_buffer_index
	LDA #$3F
	STA gfx_update_buffer, X
	INX

	LDA #$00
	STA gfx_update_buffer, X
	INX

	LDA #$1F << 1
	STA gfx_update_buffer, X
	INX

	LDY #$00
:	LDA test_palette, Y
	STA gfx_update_buffer, X
	INX
	INY
	CPY #$20
	BNE :-

	STX gfx_update_buffer_index

	LDA #PPU::MASK::RENDER_BG | PPU::MASK::RENDER_SP
	STA soft_ppumask

	LDA #<.bank(main_menu_loop)
	STA game_state_bank
	LDA #<main_menu_loop
	STA game_state_ptr + 0
	LDA #>main_menu_loop
	STA game_state_ptr + 1

; temp stuff
	LDA #$00
	STA soft_ppumask
	JSR wait_for_nmi
	JMP no_temp

.proc temp
	temp_x			:= $10	; And $11, $12
	temp_y			:= $13	; And $14, $15
	value			:= $16
	octaves			:= $17
	x_count			:= $0F
	y_count			:= $0E
	tile_x_count	:= $0D
	tile_y_count	:= $0C
	STEP_SIZE		= $10

	LDA #$00
	STA temp_x + 0
	STA temp_x + 1
	STA temp_x + 2
	STA tile_x_count

outer_loop:
	LDA #$00
	STA temp_y + 0
	STA temp_y + 1
	STA temp_y + 2
	STA tile_y_count
inner_loop:
	LDX gfx_update_buffer_index
	LDA tile_y_count
	STA gfx_update_buffer + 0, X
	LDA tile_x_count
	ASL
	ASL
	ASL
	ASL
	STA gfx_update_buffer + 1, X

	LDA #$0F << 1
	STA gfx_update_buffer + 2, X
	TXA
	AXS #<-$03
	STX gfx_update_buffer_index
	
	LDA #$08
	STA y_count
@outer:
	LDA #$08
	STA x_count
	@inner:
		LDA temp_x + 0
		STA perlin_x + 0
		LDA temp_x + 1
		STA perlin_x + 1
		LDA temp_x + 2
		STA perlin_x + 2
		LDA temp_y + 0
		STA perlin_y + 0
		LDA temp_y + 1
		STA perlin_y + 1
		LDA temp_y + 2
		STA perlin_y + 2

		LDA #$00
		STA value
		LDA #$01
		STA octaves

		@octave_loop:
			JSR perlin
			CLC
			ADC value
			STA value
			CMP #$80
			ROR value

			ASL perlin_x + 0
			ROL perlin_x + 1
			ROL perlin_x + 2
			ASL perlin_y + 0
			ROL perlin_y + 1
			ROL perlin_y + 2

			DEC octaves
			BNE @octave_loop


		LDX gfx_update_buffer_index
		ASL
		CLC
		ADC #$80
		ASL
		ROL gfx_update_buffer + 8, X
		ASL
		ROL gfx_update_buffer + 0, X

	@inc_x:
		LDA #<STEP_SIZE
		CLC
		ADC temp_x + 0
		STA temp_x + 0
		LDA #>STEP_SIZE
		ADC temp_x + 1
		STA temp_x + 1
		LDA #^STEP_SIZE
		ADC temp_x + 2
		STA temp_x + 2

	@check_inner:
		DEC x_count
		BNE @inner
		INC gfx_update_buffer_index

@inc_y:
	LDA #<STEP_SIZE
	CLC
	ADC temp_y + 0
	STA temp_y + 0
	LDA #>STEP_SIZE
	ADC temp_y + 1
	STA temp_y + 1
	LDA #^STEP_SIZE
	ADC temp_y + 2
	STA temp_y + 2

@reset_x:
	LDA temp_x + 0
	SEC
	SBC #<(STEP_SIZE * 8)
	STA temp_x + 0
	LDA temp_x + 1
	SBC #>(STEP_SIZE * 8)
	STA temp_x + 1
	LDA temp_x + 2
	SBC #^(STEP_SIZE * 8)
	STA temp_x + 2

@check_outer:
	DEC y_count
	BEQ :+ 
		JMP @outer
:	LAX gfx_update_buffer_index
	AXS #<-$08
	STX gfx_update_buffer_index

	JSR empty_gfx_update_buffer

check_inner:
	INC tile_y_count
	LDA #$10
	CMP tile_y_count
	BEQ :+
		JMP inner_loop
:

@tile_inc_x:
	LDA temp_x + 0
	CLC
	ADC #<(STEP_SIZE * 8)
	STA temp_x + 0
	LDA temp_x + 1
	ADC #>(STEP_SIZE * 8)
	STA temp_x + 1
	LDA temp_x + 2
	ADC #^(STEP_SIZE * 8)
	STA temp_x + 2

check_outer:
	INC tile_x_count
	LDA #$10
	CMP tile_x_count
	BEQ :+
		JMP outer_loop
:

fill_nametable:
	LDX #$00
	LDA #$00
	STA y_count
@outer:
	LDA #$00
	STA x_count

	LDA y_count
	ASL
	ASL
	ASL
	ASL
	ASL
	PHA
	LDA #$21
	ADC #$00
	STA PPU::ADDR
	LDA y_count
	PLA
	ORA #$08
	STA PPU::ADDR
@inner:
	STX PPU::DATA
	INX
	INC x_count
	LDA #$10
	CMP x_count
	BNE @inner

	INC y_count
	LDA #$10
	CMP y_count
	BNE @outer


.endproc

no_temp:
	LDA #<test_gfx
	STA $00
	LDA #>test_gfx
	STA $01
	JSR load_chr_block

	LDA #PPU::MASK::RENDER_BG | PPU::MASK::RENDER_SP
	STA soft_ppumask

	LDA #$01
	LDX #$08
	LDY #$08
	JSR load_object

	RTS
.endproc

.proc	main_menu_loop
	JSR read_controllers

	LDX #$00
:	LDA #$FF
	STA oam + 0, X
	TXA
	AXS #<-$04
	BNE :-
	STX oam_index

	JSR process_objects
	JSR render_objects
	JSR wait_for_nmi
	RTS
.endproc

test_palette:
.byte	$0F, $00, $10, $20
.byte	$0F, $00, $10, $20
.byte	$0F, $00, $10, $20
.byte	$0F, $00, $10, $20
.byte	$0F, $03, $13, $23
.byte	$0F, $05, $15, $25
.byte	$0F, $07, $17, $27
.byte	$0F, $09, $19, $29