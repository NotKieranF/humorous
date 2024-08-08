.ifndef NMI_INC
NMI_INC = 1

; 6502 nmi vector
.global		nmi

; Indicate that a logical frame is done, and wait for the next nmi before returning
; Trashes A
.global		wait_for_nmi

; Soft registers
.globalzp	soft_ppuctrl, soft_ppumask, soft_scroll_x, soft_scroll_y

; OAM stuff
.global		oam
.globalzp	oam_index

.endif