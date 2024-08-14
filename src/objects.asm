;
.include	"objects.inc"
.include	"nmi.inc"





.zeropage
current_object:			.res 1	; Index of the object that's currently being processed
camera_x:				.res 2
camera_y:				.res 2





.bss
object_id:				.res MAX_OBJECTS
object_flags:			.res MAX_OBJECTS		; %vhp-----
object_state:			.res MAX_OBJECTS
object_x_lo:			.res MAX_OBJECTS
object_x_hi:			.res MAX_OBJECTS
object_y_lo:			.res MAX_OBJECTS
object_y_hi:			.res MAX_OBJECTS
object_x_speed:			.res MAX_OBJECTS
object_y_speed:			.res MAX_OBJECTS
object_display_list:	.res MAX_OBJECTS + 1	; Ordered list of objects to be rendered this frame. Terminated by a negative slot index





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

; Iterates through object list and calls state routines for any non-null objects
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X, Y, $00 - $0F
.proc	process_objects
	object_state_table_ptr	:= $00	; And $01
	state_ptr				:= $00	; And $01

	LDX #MAX_OBJECTS - 1
loop:
	STX current_object
	LDY object_id, X
	BEQ @next

	; Get pointer to object's state table by indexing into universal table with object id
	LDA object_state_table_ptrs_lo, Y
	STA object_state_table_ptr + 0
	LDA object_state_table_ptrs_hi, Y
	STA object_state_table_ptr + 1

	; Get pointer to objects current state handler by indexing into object's state table with object state
	LDY object_state, X
	LAX (object_state_table_ptr), Y
	INY
	LDA (object_state_table_ptr), Y
	STX state_ptr + 0
	STA state_ptr + 1

	LDX current_object
	JSR execute_state
@next:
	LDX current_object
	DEX
	BPL loop
	RTS

execute_state:
	JMP (state_ptr)
.endproc

;
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X, Y, $00 - $0F
.proc	render_objects
	loop_count				:= $0F

	LDX #MAX_OBJECTS - 1
@loop:
	STX current_object
	LDA object_id, X
	BEQ :+
	JSR render_object
	LDX current_object
:	DEX
	BPL @loop
	RTS




	LDY #$00
:	LDX object_display_list, Y
	BMI exit
	STY loop_count
	JSR render_object
	BCS exit						; Exit prematurely if oam is full, indicated with a set carry
	LDY loop_count
	INY
	JMP :-

exit:
	RTS
.endproc

; Renders a particular object to oam
;	Takes: Object slot to render in X
;	Returns: Nothing
;	Clobbers: A, X, Y, $00 - $07
.proc	render_object
	object_screenspace_x	:= $00	; And $01
	object_screenspace_y	:= $02	; And $03
	frame_data_ptr			:= $04	; And $05
	frame_table_ptr			:= $04	; And $05
	loop_count				:= $06
	object_attr				:= $07
	flip_x					:= $08
	flip_y					:= $09

; object_screenspace_x = (object_x / 16) - camera_x
convert_x_pos:
	LDA object_x_hi, X				; Extract pixel position of object 
	STA object_screenspace_x + 1	; object_screenspace_x = object_x / 16
	LDA object_x_lo, X
	LDY #$04
:	LSR object_screenspace_x + 1
	ROR
	DEY
	BNE :-

	SEC								; Convert absolute object position to screenspace position
	SBC camera_x + 0				; object_screenspace_x = object_screenspace_x - camera_x
	STA object_screenspace_x + 0
	LDA object_screenspace_x + 1
	SBC camera_x + 1
	BEQ :+							; Don't render any objects whose origins are not on screen
		RTS
:	STA object_screenspace_x + 1

; object_screenspace_y = (object_y / 16) - camera_y
convert_y_pos:
	LDA object_y_hi, X				; Extract pixel position of object
	STA object_screenspace_y + 1	; object_screenspace_y = object_y / 16
	LDA object_y_lo, X
	LDY #$04
:	LSR object_screenspace_y + 1
	ROR
	DEY
	BNE :-

	SEC								; Convert absolute object position to screenspace position
	SBC camera_y + 0				; object_screenspace_y = object_screenspace_y - camera_y
	STA object_screenspace_y + 0
	LDA object_screenspace_y + 1
	SBC camera_y + 1
	BEQ :+							; Don't render any objects whose origins are not on screen
		RTS
:	STA object_screenspace_y + 1

check_flip:
	LDA object_flags, X
	STA object_attr
	LDY #$00							; Preload Y register with 0
	AND #OBJECT::FLAGS::FLIP_V
	BEQ :+
		DEY								; Y = $FF
		LDA object_screenspace_y + 0	; Subtract 8 from the object's screenspace y coordinate to account for sprite height when flipping
		SEC
		SBC #$08
		STA object_screenspace_y + 0
		BCS :+
			DEC object_screenspace_y + 1
:	STY flip_y							; This value is used later to negate the y offset of component sprites when flipped

	LDA object_attr
	LDY #$00
	AND #OBJECT::FLAGS::FLIP_H
	BEQ :+
		DEY								; Y = $FF
		LDA object_screenspace_x + 0	; Subtract 8 from the object's screenspace x coordinate to account for sprite width when flipping
		SEC
		SBC #$08
		STA object_screenspace_x + 0
		BCS :+
			DEC object_screenspace_x + 1
:	STY flip_x							; This value is used later to negate the x offset of component sprites when flipped

; Modify this later

setup_frame_ptr:
	LDY object_id, X
	LDA	object_frame_table_ptrs_lo, Y
	STA frame_table_ptr + 0
	LDA object_frame_table_ptrs_hi, Y
	STA frame_table_ptr + 1

	LDY #$00
	LAX (frame_table_ptr), Y
	INY
	LDA (frame_table_ptr), Y
	STX frame_data_ptr + 0
	STA frame_data_ptr + 1

init_render_object_loop:
	LDY #$00
	LDA (frame_data_ptr), Y
	STA loop_count
	LDX oam_index
render_object_loop:
@write_y_pos:
	INY
	LDA (frame_data_ptr), Y
	EOR flip_y						; Negate y offset if flip_y = $FF, otherwise do nothing
	SEC
	SBC flip_y
	CLC
	BMI :++								; If offset is negative, then carry will remain set while object is onscreen
		ADC object_screenspace_y + 0	; Otherwise, carry will remain clear while object is onscreen
		BCC :+++
:			JMP y_out_of_bounds
:		ADC object_screenspace_y + 0
		BCC :--
:	STA oam + 0, X

@write_tile:
	INY								; Tile data is copied verbatim
	LDA (frame_data_ptr), Y
	STA oam + 1, X

@write_attr:
	INY								; Object flags get xored with component sprite flags before being written
	LDA (frame_data_ptr), Y
	EOR object_attr
	STA oam + 2, X

@write_x_pos:
	INY
	LDA (frame_data_ptr), Y
	EOR flip_x						; Negate x offset if flip_x = $FF, otherwise do nothing
	SEC
	SBC flip_x
	CLC
	BMI :++								; If offset is negative, then carry will remain set while object is onscreen
		ADC object_screenspace_x + 0	; Otherwise, carry will remain clear while object is onscreen
		BCC :+++
:			JMP x_out_of_bounds
:		ADC object_screenspace_x + 0
		BCC :--
:	STA oam + 3, X

check_oam:
	TXA								; Advance index by one sprite
	AXS #<-$04
	BNE check_loop					; Check if we've wrapped to 0, i.e. oam is full
	@exit:
		STX oam_index
		SEC							; Indicate that oam is full by setting the carry flag
		RTS

y_out_of_bounds:
	INY								; Skip to next sprite in input stream
	INY
	INY
x_out_of_bounds:
	LDA #$FF						; Put Y position of written sprite offscreen
	STA oam + 0, X

check_loop:
	DEC loop_count
	BNE render_object_loop
	@exit:
		STX oam_index
		CLC							; Indicate that oam is not full by clearing the carry flag
		RTS 
.endproc





.rodata
.proc	object_state_table_ptrs_lo
	.lobytes	$0000				; Null
	.lobytes	debug_object_state_table
.endproc

.proc	object_state_table_ptrs_hi
	.hibytes	$0000				; Null
	.hibytes	debug_object_state_table
.endproc

.proc	object_frame_table_ptrs_lo
	.lobytes	$0000
	.lobytes	debug_object_frame_table
.endproc

.proc	object_frame_table_ptrs_hi
	.hibytes	$0000
	.hibytes	debug_object_frame_table
.endproc

.include	"../src/objects/debug_object.inc"