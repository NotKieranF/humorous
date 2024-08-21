; Object system
.include	"objects.inc"
.include	"nmi.inc"





.zeropage
current_object:				.res 1	; Index of the object that's currently being processed
camera_x:					.res 2
camera_y:					.res 2





.bss
object_id:					.res MAX_OBJECTS
object_flags:				.res MAX_OBJECTS	; %vhp- ----
												;  |||
												;  ||+------ Draw behind background
												;  |+------- Flip horizontally
												;  +-------- Flip vertically
object_animation_id:		.res MAX_OBJECTS	; Index into object's animation table
object_animation_frame:		.res MAX_OBJECTS	; Index into object's animation data
object_animation_timer:		.res MAX_OBJECTS	; Frames until next animation update
object_state:				.res MAX_OBJECTS	; Index into object's state table
object_x_lo:				.res MAX_OBJECTS	; Unsigned 12.4-bit position
object_x_hi:				.res MAX_OBJECTS
object_y_lo:				.res MAX_OBJECTS	; Unsigned 12.4-bit position
object_y_hi:				.res MAX_OBJECTS
object_x_speed:				.res MAX_OBJECTS	; Signed 4.4-bit speed
object_y_speed:				.res MAX_OBJECTS	; Signed 4.4-bit speed
object_depth:				.res MAX_OBJECTS	; Depth for display sorting
object_display_list:		.res MAX_OBJECTS	; Ordered list of objects to be rendered this frame
object_display_list_index:	.res 1





.code
; Loads an object into the first available object slot
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

; Sets an objects current animation
;	Takes: Animation id in A, object slot in X
;	Returns: Nothing
;	Clobbers: A
.proc	set_animation
	STA object_animation_id, X
	LDA #$01							; Trigger an immediate animation tick
	STA object_animation_timer, X
	LDA #$FF							; Animation frame overflows to $00 upon first tick
	STA object_animation_frame, X
	RTS
.endproc

; Iterates through object list and calls render_object for all non-null objects
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X, Y, $00 - $0F
.proc	render_objects
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

	DEC object_display_list_index	; Display list index points one index past the last valid entry
	BMI exit						; Exit early if display list is empty
loop:
	LDY object_display_list_index
	LDX object_display_list, Y
	JSR render_object
	DEC object_display_list_index
	BPL loop
exit:
	INC object_display_list_index	; Reset display list index to 0 for next frame
	RTS
.endproc

; Renders a particular object to oam
;	Takes: Object slot to render in X
;	Returns: Nothing
;	Clobbers: A, X, Y, $00 - $07
.proc	render_object
	object_screenspace_x	:= $00	; And $01
	object_screenspace_y	:= $02	; And $03
	frame_table_ptr			:= $04	; And $05
	animation_table_ptr		:= $06	; And $07
	frame_data_ptr			:= $08	; And $09
	animation_data_ptr		:= $0A	; And $0B
	loop_count				:= $0C
	object_attr				:= $0D
	flip_x					:= $0E
	flip_y					:= $0F

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

; Animation handling code

	LDY object_id, X
get_frame_table_ptr:
	LDA	object_frame_table_ptrs_lo, Y
	STA frame_table_ptr + 0
	LDA object_frame_table_ptrs_hi, Y
	STA frame_table_ptr + 1

get_animation_table_ptr:
	LDA object_animation_table_ptrs_lo, Y
	STA animation_table_ptr + 0
	LDA object_animation_table_ptrs_hi, Y
	STA animation_table_ptr + 1

get_animation_data_ptr:
	LDY object_animation_id, X
	LDA (animation_table_ptr), Y
	STA animation_data_ptr + 0
	INY
	LDA (animation_table_ptr), Y
	STA animation_data_ptr + 1

update_animation:
	DEC object_animation_timer, X
	BNE @no_frame_update
@frame_update:							; If the animation timer reaches 0, we must read in a new frame
		INC object_animation_frame, X
		LDY object_animation_frame, X
		INC object_animation_frame, X
		LDA (animation_data_ptr), Y		; The next byte is either the length of a new frame ($00 - $7F)
		BPL @length						; Or an animation opcode ($80 - $FF)
		@opcode:
			ASL
			TAY
			LDA opcode_ptr_table + 1, Y
			PHA
			LDA opcode_ptr_table + 0, Y
			PHA
			RTS

	@length:
		STA object_animation_timer, X

@no_frame_update:
	LDY object_animation_frame, X	; Y should hold the index of a valid frame id at this point
	LDA (animation_data_ptr), Y

get_frame_data_ptr:					; A holds the frame id
	ASL								; Indexing into table of words
	TAY
	LDA (frame_table_ptr), Y
	STA frame_data_ptr + 0
	INY
	LDA (frame_table_ptr), Y
	STA frame_data_ptr + 1

; Handle flipping logic

handle_flags:
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

; Sprite rendering code

init_render_object_loop:
	LDY #$00
	LDA (frame_data_ptr), Y
	STA loop_count
	LDX oam_index
render_object_loop:
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

opcode_ptr_table:
.word	opcode_loop - 1
.word	opcode_hang - 1
.word	opcode_jump - 1
.word	opcode_set_x_speed - 1
.word	opcode_set_y_speed - 1
.word	opcode_add_x_speed - 1
.word	opcode_add_y_speed - 1

	;
	.proc	opcode_loop
		LDA object_animation_id, X
		JSR set_animation
		JMP ::render_object::update_animation
	.endproc

	;
	.proc	opcode_hang

	.endproc

	;
	.proc	opcode_jump
		LDY object_animation_frame, X
		LDA (::render_object::animation_data_ptr), Y
		JSR set_animation
		JMP ::render_object::get_animation_data_ptr
	.endproc
	opcode_set_x_speed:
	opcode_set_y_speed:
	opcode_add_x_speed:
	opcode_add_y_speed:

.endproc

; Applies an objects current speed to its position
;	Takes: Object slot to apply speed to in X
;	Returns: Nothing
;	Clobbers: A, Y
.proc	apply_speed
	; object_x[x] += object_x_speed[x]
	LDY #$00					; Preload Y with positive sign extension
	LDA object_x_speed, X
	BPL :+
		DEY						; Y = $FF
:	CLC
	ADC object_x_lo, X
	STA object_x_lo, X
	TYA
	ADC object_x_hi, X
	STA object_x_hi, X

	; object_y[x] += object_y_speed[x]
	LDY #$00					; Preload Y with positive sign extension
	LDA object_y_speed, X
	BPL :+
		DEY						; Y = $FF
:	CLC
	ADC object_y_lo, X
	STA object_y_lo, X
	TYA
	ADC object_y_hi, X
	STA object_y_hi, X

	RTS
.endproc

; Adds an object to the display list
;	Takes: Object
;	Returns: Nothing
;	Clobbers: A, Y
.proc	add_to_display_list

.endproc





; Object definition files
.include	"../src/objects/debug_object.inc"
.include	"../src/objects/player.inc"

.rodata
.proc	object_state_table_ptrs_lo
	.lobytes	$0000				; Null
	.lobytes	::PLAYER::STATES
.endproc

.proc	object_state_table_ptrs_hi
	.hibytes	$0000				; Null
	.hibytes	::PLAYER::STATES
.endproc

.proc	object_frame_table_ptrs_lo
	.lobytes	$0000				; Null
	.lobytes	::PLAYER::FRAMES
.endproc

.proc	object_frame_table_ptrs_hi
	.hibytes	$0000				; Null
	.hibytes	::PLAYER::FRAMES
.endproc

.proc	object_animation_table_ptrs_lo
	.lobytes	$0000				; Null
	.lobytes	::PLAYER::ANIMATIONS
.endproc

.proc	object_animation_table_ptrs_hi
	.hibytes	$0000				; Null
	.hibytes	::PLAYER::ANIMATIONS
.endproc