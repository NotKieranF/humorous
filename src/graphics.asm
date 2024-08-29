.include	"nes.inc"
.include	"graphics.inc"





.code
; Loads a block of character data into chr-ram. Assumes that rendering is disabled
;	Takes: Pointer to character data in $00 - $01
;	Returns: Nothing
;	Clobbers: A
.proc	load_chr_block
	data_ptr		:= $00	; And $01
	counter			:= $02	; And $03

	LDY #$00
	LDA (data_ptr), Y
	STA counter + 0
	INY
	LDA (data_ptr), Y
	STA counter + 1
	INY

	LDA (data_ptr), Y
	STA PPU::ADDR
	INY
	LDA (data_ptr), Y
	STA PPU::ADDR

loop:
	; PPU::DATA = *(data_ptr++)
	INY
	BNE :+
		INC data_ptr + 1
:	LDA (data_ptr),  Y
	STA PPU::DATA

	INC counter + 0
	BNE loop
	INC counter + 1
	BNE loop

	RTS
.endproc





.rodata
test_gfx:
.word	-(:+ - *) & $FFFF
.byte	$10, $00
.incbin		"bokazurah.chr"
:

test_tiles:
.word	-(:+ - *) & $FFFF
.byte	$00, $00
.incbin		"test_tiles.chr"
: