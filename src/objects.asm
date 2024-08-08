.include	"objects.inc"





.bss
object_id:				.res MAX_OBJECTS
object_state:			.res MAX_OBJECTS
object_x_lo:			.res MAX_OBJECTS
object_x_hi:			.res MAX_OBJECTS
object_y_lo:			.res MAX_OBJECTS
object_y_hi:			.res MAX_OBJECTS
object_x_speed:			.res MAX_OBJECTS
object_y_speed:			.res MAX_OBJECTS
object_display_list:	.res MAX_OBJECTS





.code
; Loads
;	Takes: object_id in A, object_x_hi in X, object_y_hi in Y
;	Returns: Chosen object slot in X, or $FF if no free slots were found
;	Clobbers: A, X, Y, $00 - $01
.proc	load_object
	id			:= $00
	x_hi		:= $01

	; Stash object parameters into zp
	STA id
	STX x_hi

find_free_slot:
	LDX #MAX_OBJECTS - 1
@loop:
	LDA object_id, X
	BEQ set_object_parameters
	DEX
	BPL @loop
	RTS							; Return early if we cannot find an empty object slot

set_object_parameters:
	LDA id						; Set id and position based on provided values
	STA object_id, X
	LDA x_hi
	STA object_x_hi, X
	TYA
	STA object_y_hi, X

	LDA #$00					; Initialize everything else to sensible defaults
	STA object_state, X
	STA object_x_lo, X
	STA object_y_lo, X
	STA object_x_speed, X
	STA object_y_speed, X

	RTS
.endproc

;
;
;
;
.proc	process_objects

.endproc

;
;
;
;
.proc	render_objects

.endproc