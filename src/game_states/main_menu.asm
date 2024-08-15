.include	"main.inc"
.include	"nes.inc"
.include	"nmi.inc"
.include	"objects.inc"
.include	"controllers.inc"
.include	"perlin.inc"
.export	initial_game_state := main_menu_init

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

.proc temp
	x_count			:= $0F
	y_count			:= $0E
	tile_x_count	:= $0D
	tile_y_count	:= $0C
	STEP_SIZE		= $10

	LDA #$00
	STA perlin_x + 0
	STA perlin_x + 1
	STA perlin_x + 2
	STA tile_x_count

outer_loop:
	LDA #$00
	STA perlin_y + 0
	STA perlin_y + 1
	STA perlin_y + 2
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
		JSR perlin
		LDX gfx_update_buffer_index
		ASL
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
		ADC perlin_x + 0
		STA perlin_x + 0
		LDA #>STEP_SIZE
		ADC perlin_x + 1
		STA perlin_x + 1
		LDA #^STEP_SIZE
		ADC perlin_x + 2
		STA perlin_x + 2

	@check_inner:
		DEC x_count
		BNE @inner
		INC gfx_update_buffer_index

@inc_y:
	LDA #<STEP_SIZE
	CLC
	ADC perlin_y + 0
	STA perlin_y + 0
	LDA #>STEP_SIZE
	ADC perlin_y + 1
	STA perlin_y + 1
	LDA #^STEP_SIZE
	ADC perlin_y + 2
	STA perlin_y + 2

@reset_x:
	LDA perlin_x + 0
	SEC
	SBC #<STEP_SIZE * 8
	STA perlin_x + 0
	LDA perlin_x + 1
	SBC #>STEP_SIZE * 8
	STA perlin_x + 1
	LDA perlin_x + 2
	SBC #^STEP_SIZE * 8
	STA perlin_x + 2

@check_outer:
	DEC y_count
	BNE @outer
	LAX gfx_update_buffer_index
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
	LDA perlin_x + 0
	CLC
	ADC #<STEP_SIZE * 8
	STA perlin_x + 0
	LDA perlin_x + 1
	ADC #>STEP_SIZE * 8
	STA perlin_x + 1
	LDA perlin_x + 2
	ADC #^STEP_SIZE * 8
	STA perlin_x + 2

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

	LDA #PPU::MASK::RENDER_BG | PPU::MASK::RENDER_SP
	STA soft_ppumask

;	STEP_SIZE = $08
;
;	LDA #$00
;	STA $FF
;	STA $FE
;	STA perlin_y + 0
;	STA perlin_y + 1
;	STA perlin_y + 2
;@outer:
;	LDA #$00
;	STA perlin_x + 0
;	STA perlin_x + 1
;	STA perlin_x + 2
;@inner:
;	JSR perlin
;
;	LDA #STEP_SIZE
;	CLC
;	ADC perlin_x + 0
;	STA perlin_x + 0
;	BCC :+
;		INC perlin_x + 1
;:	INC $FF
;	BNE @inner
;
;	LDA #STEP_SIZE
;	CLC
;	ADC perlin_y + 0
;	STA perlin_y + 0
;	BCC :+
;		INC perlin_y + 1
;:	INC $FE
;	BNE @outer
;
	LDA #$01
	LDX #$08
	LDY #$08
	JSR load_object

	RTS
.endproc

.proc	main_menu_loop
	LDX #$00
:	LDA #$FF
	STA oam + 0, X
	TXA
	AXS #<-$04
	BNE :-
	STX oam_index

	JSR process_objects
	JSR render_objects
	JSR read_four_score
	JSR update_controller_state
	JSR wait_for_nmi
	RTS
.endproc

test_palette:
.byte	$0F, $00, $10, $20
.byte	$0F, $00, $10, $20
.byte	$0F, $00, $10, $20
.byte	$0F, $00, $10, $20
.byte	$0F, $2D, $00, $10
.byte	$0F, $05, $15, $25
.byte	$0F, $07, $17, $27
.byte	$0F, $09, $19, $29