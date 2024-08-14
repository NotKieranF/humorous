.include	"main.inc"
.include	"nes.inc"
.include	"nmi.inc"
.include	"objects.inc"
.include	"controllers.inc"
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
.byte	$0F, $0F, $0F, $0F
.byte	$0F, $0F, $0F, $0F
.byte	$0F, $0F, $0F, $0F
.byte	$0F, $0F, $0F, $0F
.byte	$0F, $2D, $00, $10
.byte	$0F, $05, $15, $25
.byte	$0F, $07, $17, $27
.byte	$0F, $09, $19, $29