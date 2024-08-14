.include	"main.inc"
.include	"mapper.inc"
.include	"nmi.inc"
.include	"nes.inc"
; First game state to be ran. Should have matching .export statement in another file
.import		initial_game_state
; Mark main to be run after initialization
.export		post_reset := main





.zeropage
game_state_ptr:				.res 2
game_state_bank:			.res 1





.code
.proc	main
	; Setup NMIs
	LDA #PPU::CTRL::ENABLE_NMI
	STA soft_ppuctrl
	STA PPU::CTRL

	; Setup pointer to initial game state
	LDA #<.bank(initial_game_state)
	STA game_state_bank
	LDA #<initial_game_state
	STA game_state_ptr + 0
	LDA #>initial_game_state
	STA game_state_ptr + 1

kernal_loop:
	LDA game_state_bank
	JSR switch_prg_bank_interruptable
	JSR execute_game_state
	JMP kernal_loop

execute_game_state:
	JMP (game_state_ptr)
.endproc