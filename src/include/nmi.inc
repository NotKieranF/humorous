.ifndef NMI_INC
NMI_INC = 1

; 6502 nmi vector
.global		nmi

; Indicate that a logical frame is done, and wait for the next nmi before returning
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A
.global		wait_for_nmi

; Clear oam buffer by placing all sprites offscreen
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X
.global		clear_oam

; Consumes the contents of the gfx_update_buffer. May be called outside of NMI, but care should be taken to ensure that rendering is disabled, and the frame_done_flag is clear
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X
.global		empty_gfx_update_buffer

; Graphical update buffer. Packets are roughly NES stripe image, minus RLE: [dest, length, data]*, $FF
;	dest: VRAM address to write to PPU::ADDR, big endian
;	length: of the form %dllllll0
;	                     |||||||
;	                     |++++++-- length of packet - 1
;	                     +-------- direction, 0 for horizontal (inc-by-1), 1 for vertical (inc-by-32)
;	data: data to write to PPU::DATA
.global		gfx_update_buffer
.globalzp	gfx_update_buffer_index

; Helper macro for combining gfx packet lengths and directions into one value
.define		GFX_PACKET_LENGTH(length, direction) ((length - 1) << 1 | direction << 7)

; Soft registers
.globalzp	soft_ppuctrl, soft_ppumask, soft_scroll_x, soft_scroll_y

; OAM buffer stuff
.global		oam
.globalzp	oam_index

; CPU accessible copy of attribute table
.global		attribute_buffer

.endif