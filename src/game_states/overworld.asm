.include	"main.inc"
.include	"nmi.inc"
.include	"nes.inc"
.include	"objects.inc"
.include	"graphics.inc"
.include	"controllers.inc"
.export	initial_game_state := overworld_init
; Playfield buffer dimensions. Outermost ring of tiles <TODO>
PLAYFIELD_WIDTH		= 32 ; 21
PLAYFIELD_HEIGHT	= 32 ; 20





.bss
camera_x_old:				.res 2	; Previous frame's camera position
camera_y_old:				.res 2
camera_x_mod:				.res 1	; Camera tile x position mod PLAYFIELD_WIDTH
camera_y_mod:				.res 1	; Camera tile y position mod PLAYFIELD_HEIGHT
screen_x:					.res 1
screen_y:					.res 1
scroll_delta_x:				.res 1	; Valid range of -8 to 8
scroll_delta_y:				.res 1
playfield_buffer:			.res PLAYFIELD_WIDTH * PLAYFIELD_HEIGHT





.code
.proc	overworld_init
	; Load in test palette
	LDA #$3F
	STA PPU::ADDR
	LDA #$00
	STA PPU::ADDR

	LDX #$00
:	LDA test_palette, X
	STA PPU::DATA
	INX
	CPX #$20
	BNE :-

	; Load in test tile graphics
	LDA #<test_tiles
	STA $00
	LDA #>test_tiles
	STA $01
	JSR load_chr_block

	; Load in test sprite graphics
	LDA #<test_gfx
	STA $00
	LDA #>test_gfx
	STA $01
	JSR load_chr_block

	; Setup PPU state
	LDA #PPU::MASK::CLIP_SP | PPU::MASK::CLIP_BG
	STA soft_ppumask

	; Load player object
	LDA #$01
	LDX #$08
	LDY #$08
	JSR load_object

	; Load test level into playfield
	LDA #<playfield_buffer
	STA $00
	LDA #>playfield_buffer
	STA $01
	LDA #<test_level
	STA $02
	LDA #>test_level
	STA $03

	LDX #PLAYFIELD_HEIGHT
@outer:
	LDY #PLAYFIELD_WIDTH - 1
@inner:
	LDA ($02), Y
	STA ($00), Y
	DEY
	BPL @inner

	LDA #<PLAYFIELD_WIDTH
	CLC
	ADC $00
	STA $00
	LDA #>PLAYFIELD_WIDTH
	ADC $01
	STA $01

	LDA #<PLAYFIELD_WIDTH
	CLC
	ADC $02
	STA $02
	LDA #>PLAYFIELD_WIDTH
	ADC $03
	STA $03

	DEX
	BNE @outer

	; Switch gamemode to overworld loop
	LDA #<.bank(overworld_loop)
	STA game_state_bank
	LDA #<overworld_loop
	STA game_state_ptr + 0
	LDA #>overworld_loop
	STA game_state_ptr + 1

	RTS
.endproc

.proc	overworld_loop
	JSR read_controllers
	JSR process_objects

	; Compute scroll delta based on player's position
	JSR get_scroll_delta

	; Backup screen and camera x position
	LDA camera_x + 0
	STA camera_x_old + 0
	LDA camera_x + 1
	STA camera_x_old + 1

	; Apply scroll delta to camera_x
	LDA scroll_delta_x
	BPL :+
		DEC camera_x + 1		; Compensate when adding negative deltas
:	CLC
	ADC camera_x + 0
	STA camera_x + 0
	LDA #$00
	ADC camera_x + 1
	STA camera_x + 1

	; Queue column updates
	BIT scroll_delta_x
	BPL :+
		LDA scroll_delta_x
		BEQ :+
			LDA camera_x
			EOR camera_x_old
			AND #%11111000
			BEQ :+
				JSR queue_column
:
	; Add scroll delta x to screen position
	LDA scroll_delta_x
	CLC
	ADC screen_x
	STA screen_x

	; Change camera x mod
	LDA camera_x_old + 0
	EOR camera_x + 0
	AND #%11110000
	BEQ :++
		BIT scroll_delta_x
		BMI :+
			LDA #PLAYFIELD_WIDTH
			SEC
			ISC camera_x_mod
			BNE :++
				STA camera_x_mod
				BEQ :++
	:	DEC camera_x_mod
		BPL :+
			LDA #PLAYFIELD_WIDTH - 1
			STA camera_x_mod
:

	; Queue column updates
	BIT scroll_delta_x
	BMI :+
		LDA scroll_delta_x
		BEQ :+
			LDA camera_x
			EOR camera_x_old
			AND #%11111000
			BEQ :+
				JSR queue_column
:




	; Backup screen and camera y position
	LDA camera_y + 0
	STA camera_y_old + 0
	LDA camera_y + 1
	STA camera_y_old + 1

	; Apply scroll delta to camera_y
	LDA scroll_delta_y
	BPL :+
		DEC camera_y + 1		; Compensate when adding negative deltas
:	CLC
	ADC camera_y + 0
	STA camera_y + 0
	LDA #$00
	ADC camera_y + 1
	STA camera_y + 1

	; Queue row updates
	BIT scroll_delta_y
	BPL :+
		LDA scroll_delta_y
		BEQ :+
			LDA camera_y
			EOR camera_y_old
			AND #%11111000
			BEQ :+
				JSR queue_row
:
	; Add scroll delta y to screen position
	LDA scroll_delta_y
	CLC
	BMI @neg
	@pos:
		ADC screen_y
		BCC :+
			SBC #256 - 240
	:	CMP #240
		BCC :+
			SBC #240
	:	STA screen_y
		JMP @done

	@neg:
		ADC screen_y
		BCS :+
			SBC #(256 - 240) - 1	; Carry is CLEAR
	:	CMP #240
		BCC :+
			SBC #240
	:	STA screen_y

	@done:

	; Change camera_y_mod
	LDA camera_y_old + 0
	EOR camera_y + 0
	AND #%11110000
	BEQ :++
		BIT scroll_delta_y
		BMI :+
			LDA #PLAYFIELD_HEIGHT
			SEC
			ISC camera_y_mod
			BNE :++
				STA camera_y_mod
				BEQ :++
	:	DEC camera_y_mod
		BPL :+
			LDA #PLAYFIELD_HEIGHT - 1
			STA camera_y_mod
:

	; Queue row updates
	BIT scroll_delta_y
	BMI :+
		LDA scroll_delta_y
		BEQ :+
			LDA camera_y
			EOR camera_y_old
			AND #%11111000
			BEQ :+
				JSR queue_row
:
	; Set scroll
	LDA screen_x
	STA soft_scroll_x
	LDA screen_y
	STA soft_scroll_y

	; Queue attribute updates
	LDX gfx_update_buffer_index
	LDA #$23
	STA gfx_update_buffer + 0, X
	LDA #$C0
	STA gfx_update_buffer + 1, X
	LDA #GFX_PACKET_LENGTH 64, 0
	STA gfx_update_buffer + 2, X
	TXA
	AXS #<-3
	LDY #$00
:	LDA attribute_buffer, Y
	STA gfx_update_buffer, X
	INX
	INY
	CPY #$40
	BNE :-
	STX gfx_update_buffer_index

	; camera_x_old = camera_x; camera_y_old = camera_y
	; Move camera
	; camera_x_mod += (camera_x_old / 256) - (camera_x /256)
	; if camera_x_mod < 0
	;	camera_x_mod += PLAYFIELD_WIDTH
	; if camera_x_mod >= PLAYFIELD_WIDTH
	;	camera_x_mod -= PLAYFIELD_WIDTH 

	JSR clear_oam
	JSR render_objects
	JSR wait_for_nmi
	RTS
.endproc

;
;	Takes:
;	Returns:
;	Clobbers:
.proc	sample_playfield
	input_x			:= $00	; And $01
	input_y			:= $02	; And $03
	playfield_ptr	:= $02	; And $03

get_y_mod:
	; relative_y = input_y - camera_y
	LDA input_y + 0
	SEC
	SBC camera_y + 0
	LDA input_y + 1
	SBC camera_y + 1

	; Effectively compute relative_y_mod = (relative_y + camera_y_mod) % PLAYFIELD_HEIGHT
	; Assumes |relative_y| <= PLAYFIELD_HEIGHT
	; relative_y_mod = relative_y + camera_y_mod
	CLC
	ADC camera_y_mod
	; if (relative_y_mod < 0) {relative_y_mod += PLAYFIELD_HEIGHT
	BMI :+
		CLC
		ADC #PLAYFIELD_HEIGHT
:	; if (relative_y_mod >= PLAYFIELD_HEIGHT) {relative_y_mod -= PLAYFIELD_HEIGHT}
	CMP #PLAYFIELD_HEIGHT
	BCC :+
	;	SEC
		SBC #PLAYFIELD_HEIGHT
:	TAY

	; playfild_ptr = &playfield + relative_y_mod * PLAYFIELD_WIDTH
	LDA row_to_playfield_ptr_lut_lo, Y
	STA playfield_ptr + 0
	LDA row_to_playfield_ptr_lut_hi, Y
	STA playfield_ptr + 1

get_x_mod:
	; relative_x = input_x - camera_x
	LDA input_x + 0
	SEC
	SBC camera_x + 0
	LDA input_x + 1
	SBC camera_x + 1

	; Effectively compute relative_x_mod = (relative_x + camera_x_mod) % PLAYFIELD_WIDTH
	; Assumes |relative_x| <= PLAYFIELD_WIDTH
	; relative_x_mod = relative_x + camera_x_mod
	CLC
	ADC camera_x_mod
	; if (relative_x_mod < 0) {relative_x_mod += PLAYFIELD_WIDTH}
	BMI :+
		CLC
		ADC #PLAYFIELD_WIDTH
:	; if (relative_x_mod >= PLAYFIELD_WIDTH) {relative_x_mod -= PLAYFIELD_WIDTH}
	CMP #PLAYFIELD_WIDTH
	BCC :+
	;	SEC
		SBC #PLAYFIELD_WIDTH
:	TAY

	; value = *(playfield_ptr + relative_x_mod)
	LDA (playfield_ptr), Y

	RTS
.endproc

;
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X, $00 - $03
.proc	get_scroll_delta
	target_x		:= $00	; And $01
	target_y		:= $02	; And $03

get_target_x:
	LDA object_x_hi + 7
	STA target_x + 1
	LDA object_x_lo + 7
	LDX #$04
	:	LSR target_x + 1
		ROR
		DEX
		BNE :-
	SEC
	SBC #<(256 / 2)
	STA target_x + 0

get_target_y:
	LDA object_y_hi + 7
	STA target_y + 1
	LDA object_y_lo + 7
	LDX #$04
	:	LSR target_y + 1
		ROR
		DEX
		BNE :-
	SEC
	SBC #<(240 / 2)
	STA target_y + 0

compute_delta_x:
	LDA target_x + 0
	SEC
	SBC camera_x + 0
	STA scroll_delta_x

compute_delta_y:
	LDA target_y + 0
	SEC
	SBC camera_y + 0
	STA scroll_delta_y

	RTS
.endproc

;
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X, Y, $00 - 
.proc	queue_column
	column_buffer_ptr		:= $00	; And $01
	playfield_ptr			:= $02	; And $03
	current_x_mod			:= $04
	current_y_mod			:= $05
	current_x_tile			:= $06
	current_y_tile			:= $07
	corner_index			:= $08
	loop_count				:= $09
	column_buffer_index		:= $0A

	; Write update packet header
write_packet_header:
	LDX gfx_update_buffer_index
	; Target address = $2000 + screen_x >> 3
	LDA #$20
	STA gfx_update_buffer + 0, X
	LDA screen_x
	LSR
	LSR
	LSR
	STA gfx_update_buffer + 1, X
	; Bit 3 of screen_x determines whether we're updating the left or right half of a column of tiles
	AND #%00000001
	STA corner_index
	; Updating a column of 30 tiles, moving down
	LDA #GFX_PACKET_LENGTH 30, 1
	STA gfx_update_buffer + 2, X
	; Skip over packet header bytes
	TXA
	AXS #<-3
	; Skip over packet data bytes
	TXA							; A now holds the index of the first byte of packet data
	AXS #<-30
	STX gfx_update_buffer_index

	; Construct pointer to column packet data
construct_column_ptr:
	CLC
	ADC #<gfx_update_buffer
	STA column_buffer_ptr + 0
	LDA #>gfx_update_buffer		; Hi byte should never change
	STA column_buffer_ptr + 1

	; Read column of tiles starting from
	LDA camera_x_mod
	BIT scroll_delta_x
	BMI :+
		CLC
		ADC #16
		CMP #PLAYFIELD_WIDTH
		BCC :+
			SBC #PLAYFIELD_WIDTH
:	STA current_x_mod
	LDA camera_y_mod
	STA current_y_mod

	; Construct initial pointer to playfield row based on current Y position
	LDY current_y_mod
	LDA row_to_playfield_ptr_lut_lo, Y
	STA playfield_ptr + 0
	LDA row_to_playfield_ptr_lut_hi, Y
	STA playfield_ptr + 1

	; Construct initial index into column buffer
	LDA screen_y
	LSR
	LSR
	LSR
	STA column_buffer_index
	; Bit 3 of screen_y determines whether we're initially updating the top or bottom half of a tile
	LSR
	ROL corner_index

	; Fill a whole 30 tile column
	LDA #30 + 1
	STA loop_count
loop:
	; Alternate writing the tops/bottoms of tiles
	LAX corner_index
	EOR #%00000001
	STA corner_index

	;
	LDA corner_routines_hi, X	; X = unmodified corner index
	PHA
	LDA corner_routines_lo, X
	PHA
	LDY current_x_mod			; Load tile id at curent position before executing corner handler
	LAX (playfield_ptr), Y
	RTS

loop_check:
	LDY column_buffer_index
	STA (column_buffer_ptr), Y

	; Increment column buffer index, wrapping around at 30
	LDA #30
	SEC
	ISC column_buffer_index
	BNE :+
		STA column_buffer_index
:
	; Check loop condition
	DEC loop_count
	BNE loop

	RTS

corner_routines_lo:
.lobytes	handle_top_left - 1
.lobytes	handle_bottom_left - 1
.lobytes	handle_top_right - 1
.lobytes	handle_bottom_right - 1

corner_routines_hi:
.hibytes	handle_top_left - 1
.hibytes	handle_bottom_left - 1
.hibytes	handle_top_right - 1
.hibytes	handle_bottom_right - 1

handle_top_left:
	LDA metatile_top_left, X
	JMP loop_check

handle_bottom_left:
	; Increment current y position, mod PLAYFIELD_HEIGHT
	LDA #PLAYFIELD_HEIGHT
	SEC
	ISC current_y_mod
	BNE :+
		STA current_y_mod
:	; Recompute playfield ptr based on new y position
	LDY current_y_mod
	LDA row_to_playfield_ptr_lut_lo, Y
	STA playfield_ptr + 0
	LDA row_to_playfield_ptr_lut_hi, Y
	STA playfield_ptr + 1

	LDA metatile_bottom_left, X
	JMP loop_check

handle_top_right:
	LDA metatile_top_right, X
	JMP loop_check

handle_bottom_right:
	; Increment current y position, mod PLAYFIELD_HEIGHT
	LDA #PLAYFIELD_HEIGHT
	SEC
	ISC current_y_mod
	BNE :+
		STA current_y_mod
:	; Recompute playfield ptr based on new y position
	LDY current_y_mod
	LDA row_to_playfield_ptr_lut_lo, Y
	STA playfield_ptr + 0
	LDA row_to_playfield_ptr_lut_hi, Y
	STA playfield_ptr + 1

	LDA metatile_bottom_right, X
	PHA

	LDA metatile_attributes, X
	AND #%00000011
	TAY

	LDA screen_x
	LSR
	LSR
	LSR
	LSR
	AND #%00000001
	STA $0F
	LDA column_buffer_index
	AND #%00000010
	ORA $0F
	TAX
	LDA attribute_identity_table, Y
	AND attribute_mask_table, X
	STA $0E

	LDA screen_x
	LSR
	LSR
	LSR
	LSR
	LSR
	STA $0F
	LDA column_buffer_index
	ASL
	AND #%00111000
	ORA $0F
	TAY
	LDA attribute_buffer, Y
	AND attribute_inverse_mask_table, X
	ORA $0E
	STA attribute_buffer, Y

	PLA
	JMP loop_check

.endproc

;
;
;
;
.proc	queue_row
	row_buffer_ptr			:= $00	; And $01
	playfield_ptr			:= $02	; And $03
	current_x_mod			:= $04
	current_y_mod			:= $05
	corner_index			:= $06
	row_buffer_index		:= $07
	loop_count				:= $08	

	; Write update packet header
write_packet_header:
	LDX gfx_update_buffer_index
	; Target address = $2000 + (screen_y & %11111000 << 2)
	LDA #$20 >> 2				; Preshift right twice
	STA gfx_update_buffer + 0, X
	LDA screen_y
	AND #%11111000
	ASL
	ROL gfx_update_buffer + 0, X
	ASL
	ROL gfx_update_buffer + 0, X
	STA gfx_update_buffer + 1, X
	; Bit 3 of screen__old determines whether we're updating the top or bottom half of a row of tiles
	AND #%00001000 << 2
	BEQ :+
		LDA #%00000001
:	STA corner_index
	; Updating a row of 32 tiles, moving right
	LDA #GFX_PACKET_LENGTH 32, 0
	STA gfx_update_buffer + 2, X
	; Skip over packet header bytes
	TXA
	AXS #<-3
	; Skip over packet data bytes
	TXA							; A now holds the index of the first byte of packet data
	AXS #<-32
	STX gfx_update_buffer_index

	; Construct pointer to column packet data
construct_column_ptr:
	CLC
	ADC #<gfx_update_buffer
	STA row_buffer_ptr + 0
	LDA #>gfx_update_buffer		; Hi byte should never change
	STA row_buffer_ptr + 1

	; Read column of tiles starting from
	LDA camera_y_mod
	BIT scroll_delta_y
	BMI :+
		CLC
		ADC #15
		CMP #PLAYFIELD_HEIGHT
		BCC :+
			SBC #PLAYFIELD_HEIGHT
:	STA current_y_mod
	LDA camera_x_mod
	STA current_x_mod

	; Construct initial pointer to playfield row based on current Y position
	LDY current_y_mod
	LDA row_to_playfield_ptr_lut_lo, Y
	STA playfield_ptr + 0
	LDA row_to_playfield_ptr_lut_hi, Y
	STA playfield_ptr + 1

	; Construct initial index into row buffer
	LDA screen_x
	LSR
	LSR
	LSR
	STA row_buffer_index
	; Bit 3 of screen_x determines whether we're initially updating the left or right half of a tile
	LSR
	ROL corner_index

	; Fill a whole 32 tile row
	LDA #32 + 1
	STA loop_count
loop:
	; Alternate writing the left/right halves of tiles
	LAX corner_index
	EOR #%00000001
	STA corner_index

	;
	LDA corner_routines_hi, X	; X = unmodified corner index
	PHA
	LDA corner_routines_lo, X
	PHA
	LDY current_x_mod			; Load tile id at curent position before executing corner handler
	LAX (playfield_ptr), Y
	RTS

loop_check:
	LDY row_buffer_index
	STA (row_buffer_ptr), Y

	; Increment row buffer index, wrapping around at 32
	LDA #32
	SEC
	ISC row_buffer_index
	BNE :+
		STA row_buffer_index
:
	; Check loop condition
	DEC loop_count
	BNE loop

	RTS

corner_routines_lo:
.lobytes	handle_top_left - 1
.lobytes	handle_top_right - 1
.lobytes	handle_bottom_left - 1
.lobytes	handle_bottom_right - 1

corner_routines_hi:
.hibytes	handle_top_left - 1
.hibytes	handle_top_right - 1
.hibytes	handle_bottom_left - 1
.hibytes	handle_bottom_right - 1

handle_top_left:
	LDA metatile_top_left, X
	JMP loop_check

handle_bottom_left:
	LDA metatile_bottom_left, X
	JMP loop_check

handle_top_right:
	; Increment current x position, mod PLAYFIELD_WIDTH
	LDA #PLAYFIELD_WIDTH
	SEC
	ISC current_x_mod
	BNE :+
		STA current_x_mod
:
	LDA metatile_top_right, X
	JMP loop_check

handle_bottom_right:
	; Increment current x position, mod PLAYFIELD_WIDTH
	LDA #PLAYFIELD_WIDTH
	SEC
	ISC current_x_mod
	BNE :+
		STA current_x_mod
:
	LDA metatile_bottom_right, X
	PHA

	LDA metatile_attributes, X
	AND #%00000011
	TAY

	LDA screen_y
	LSR
	LSR
	LSR
	AND #%00000010
	STA $0F
	LDA row_buffer_index
	LSR
	AND #%00000001
	ORA $0F
	TAX
	LDA attribute_identity_table, Y
	AND attribute_mask_table, X
	STA $0E

	LDA row_buffer_index
	LSR
	LSR
	STA $0F
	LDA screen_y
	LSR
	LSR
	AND #%00111000
	ORA $0F
	TAY
	LDA attribute_buffer, Y
	AND attribute_inverse_mask_table, X
	ORA $0E
	STA attribute_buffer, Y

	PLA
	JMP loop_check
.endproc





.rodata
metatile_top_left:
.byte	$06, $00, $11, $04
metatile_top_right:
.byte	$06, $03, $12, $05
metatile_bottom_left:
.byte	$06, $30, $21, $14
metatile_bottom_right:
.byte	$06, $33, $22, $15
metatile_attributes:
.byte	%00, %01, %10, %11


row_to_playfield_ptr_lut_lo:
.repeat	PLAYFIELD_HEIGHT, i
	.lobytes	playfield_buffer + i * PLAYFIELD_WIDTH
.endrep
row_to_playfield_ptr_lut_hi:
.repeat	PLAYFIELD_HEIGHT, i
	.hibytes	playfield_buffer + i * PLAYFIELD_WIDTH
.endrep

; Helper tables for modifying attribute data
attribute_identity_table:
.byte	%00000000, %01010101, %10101010, %11111111
attribute_mask_table:
.byte	%00000011, %00001100, %00110000, %11000000
attribute_inverse_mask_table:
.byte	%11111100, %11110011, %11001111, %00111111

.proc	test_palette
	.byte	$0F, $04, $14, $24
	.byte	$0F, $00, $10, $20
	.byte	$0F, $0A, $1A, $2A
	.byte	$0F, $0C, $1C, $2C

	.byte	$0F, $03, $13, $23
	.byte	$0F, $05, $15, $25
	.byte	$0F, $07, $17, $27
	.byte	$0F, $09, $19, $29
.endproc
.proc	test_level
	.byte	$01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01
	.byte	$01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
.endproc