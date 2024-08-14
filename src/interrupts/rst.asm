; Reset handler
.include	"rst.inc"
.include	"nes.inc"
.include	"mapper.inc"
; Code to jump to after initialization. Should have a matching .EXPORT in another translation unit
.import		post_reset
.import		__CONSTRUCTOR_TABLE__, __CONSTRUCTOR_COUNT__



.code
.proc	rst
	ptr						:= $00	; And $01

	SEI								; Ignore IRQs
	LDA #$40
	STA $4017						; Disable APU IRQ
	LDX #$FF
	TXS								; Set up stack pointer
	INX
	STX PPU::CTRL					; Disable NMIs
	STX PPU::MASK					; Disable rendering
	STX $4010						; Disable DMC IRQs				

vblank_wait_1:
	BIT PPU::STATUS					; First wait for vblank
	BPL vblank_wait_1

clear_ram:
	LDA #$07						; Setup pointer to clear RAM. Clear page 7 first, working all the way down to page 0
	STA ptr + 1
	STX ptr + 0						; X = 0

	TXA								; A = X = 0
	TAY								; Y = A = 0
@loop:
	STA (ptr), Y
	DEY
	BNE @loop
	DEC ptr + 1
	BPL @loop
	STA ptr + 1						; Hi byte of pointer is left as $FF, so needs to be cleared

run_constructors:
	.assert __CONSTRUCTOR_COUNT__ * 2 < 256, error, "Constructor table too big!"
	LDX #<__CONSTRUCTOR_COUNT__ * 2
@loop:
	DEX								; Indexing into a table of words, back to front, so hi bytes come first
	LDA __CONSTRUCTOR_TABLE__, X
	STA ptr + 1
	DEX
	LDA __CONSTRUCTOR_TABLE__, X
	STA ptr + 0

	TXA								; Save index on the stack to make as few assumptions as possible about what state constructors save
	PHA
	JSR jsr_indirect
	PLA
	TAX
	BNE @loop

vblank_wait_2:
	BIT PPU::STATUS					; Second wait for vblank, PPU is ready after this
	BPL vblank_wait_2

vblank_wait_3:
	BIT PPU::STATUS					; This is needed in mesen for whatever reason. It really shouldn't be
	BPL vblank_wait_3

	CLI								; Accept IRQs
	JMP post_reset

jsr_indirect:
	JMP (ptr)
.endproc