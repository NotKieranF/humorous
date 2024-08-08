; NMI handler
.include	"nmi.inc"
.include	"irq.inc"
.include	"nes.inc"



.zeropage
soft_ppuctrl:		.RES 1
soft_ppumask:		.RES 1
soft_scroll_x:		.RES 1
soft_scroll_y:		.RES 1
frame_done_flag:	.RES 1
oam_index:			.RES 1



.segment	"OAM"
oam:				.RES 256



.code
.proc	nmi
	PHA
	TXA
	PHA
	TYA
	PHA

check_frame_done_flag:
	LDA frame_done_flag
	BEQ no_gfx_update

; Clear write latch
	BIT PPU::STATUS

update_registers:
	LDA #>oam
	STA PPU::OAMDMA
	LDA soft_ppuctrl
	STA PPU::CTRL
	LDA soft_ppumask
	STA PPU::MASK
	LDA soft_scroll_x
	STA PPU::SCROLL
	LDA soft_scroll_y
	STA PPU::SCROLL

clear_frame_done_flag:
	LDA #$00
	STA frame_done_flag

; All timing sensitive updates have been performed, we can now enable interrupts
no_gfx_update:
	CLI

restore_registers:
	PLA
	TAY
	PLA
	TAX
	PLA

	RTI
.endproc

; Indicate that a logical frame is done, and wait for the next nmi before returning
; Trashes A
.proc	wait_for_nmi
	INC frame_done_flag
:	LDA frame_done_flag
	BNE :-
	RTS
.endproc