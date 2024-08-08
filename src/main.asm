.include	"main.inc"
; First game state to be ran. Should have matching .export statement in another file
.import		initial_game_state
; Mark main to be run after initialization
.export		post_reset := main





.zeropage
game_state_ptr:				.res 2
game_state_bank:			.res 1





.code
.proc	main
:	JMP :-
.endproc