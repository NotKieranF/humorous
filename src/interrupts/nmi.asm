; NMI handler
.include	"nmi.inc"
.include	"irq.inc"
.include	"nes.inc"
GFX_UPDATE_BUFFER_PADDING	= 6	; Padding to ensure no stack-smashing occurs if a popslide gets interrupted





.zeropage
soft_ppuctrl:				.res 1
soft_ppumask:				.res 1
soft_scroll_x:				.res 1
soft_scroll_y:				.res 1
frame_done_flag:			.res 1
oam_index:					.res 1
gfx_update_buffer_index:	.res 1
stack_ptr:					.res 1	; Used to temporarily save to stack pointer when performing a popslide
popslide_addr:				.res 2	; Address to jump to when performing an unrolled popslide





.segment	"OAM"
oam:						.res 256





.segment	"STACK"
gfx_update_buffer_padding:	.res GFX_UPDATE_BUFFER_PADDING
gfx_update_buffer:			.res 192





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

empty_buffer:
	JSR empty_gfx_update_buffer

update_registers:
	LDA soft_ppuctrl
	STA PPU::CTRL
	LDA soft_ppumask
	STA PPU::MASK
	LDA soft_scroll_x
	STA PPU::SCROLL
	LDA soft_scroll_y
	STA PPU::SCROLL
	LDA #$00
	STA PPU::OAMADDR
	LDA #>oam
	STA PPU::OAMDMA

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
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A
.proc	wait_for_nmi
	INC frame_done_flag
:	LDA frame_done_flag
	BNE :-
	RTS
.endproc

; Consumes the contents of the gfx_update_buffer. May be called outside of NMI, but care should be taken to ensure that rendering is disabled, and the frame_done_flag is clear
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X
.proc	empty_gfx_update_buffer
	BIT PPU::STATUS					; Clear write latch

add_terminator:
	LDA #$FF
	LDX gfx_update_buffer_index
	STA gfx_update_buffer, X

init_popslide:
	TSX								; Save current stack pointer
	STX stack_ptr
	LDX #<(gfx_update_buffer - 1)	; Setup new stack pointer at head of update buffer
	TXS
	LDA #>popslide					; Initialize hi byte of Duff's device pointer
	STA popslide_addr + 1

popslide_loop:
	PLA								; Read hi byte of destination address
	BMI exit						; PPU address space is only 16KiB, so any negative value is the buffer terminator
	STA PPU::ADDR
	PLA								; Read lo byte of destination address
	STA PPU::ADDR

@read_length:
	PLA								; Read packet length byte
	ASL								; Shift direction bit into carry
	EOR #%11111100					; Invert length value for lo byte of Duff's device address, with a minimum of 1 iteration
	STA popslide_addr + 0

@check_direction:
	LDA #PPU::CTRL::INC_1
	BCC :+
	LDA #PPU::CTRL::INC_32
:	STA PPU::CTRL

@execute_duff:
	JMP (popslide_addr)

exit:
	LDX stack_ptr					; Restore stack pointer and reset graphics buffer index
	TXS
	LDX #$00
	STX gfx_update_buffer_index
	LDA soft_ppuctrl				; Return PPU::CTRL to its proper state
	STA PPU::CTRL

	RTS

; Aligned to the nearest page to ensure the Duff's device address calculation never overflows into the hi byte 
.align	256
popslide:
.repeat	64
	PLA
	STA PPU::DATA
.endrep
	JMP popslide_loop
.endproc