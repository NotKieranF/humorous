.ifndef	MAPPER_INC
MAPPER_INC = 1

; One time mapper initialization
; On Action53 it sets up outer bank and mode registers
; On UNROM512 it just sets up the semaphore_ptr
; Trashes A
.global		init_mapper

; Switches the 16KiB bank at $8000 based on the value in A in an interrupt safe manner
; Trashes Y
.global		switch_prg_bank_interruptable

; Switches the 16KiB bank at CPU $8000 based on the value in A. Doesn't deflect writes, but should be used in interrupt handlers and should not be used elsewhere
; Trashes Y
; 24 cycles, including JSR/RTS
.global		switch_prg_bank_interruptor

; Switches the 8KiB bank at PPU $0000 based on the value in A, deflecting any interrupted writes
; Trashes Y
; 44 cycles, including JSR/RTS
.global		switch_chr_bank_interruptor

; Switches the mirroring mode based on the value in A, deflecting any interrupted writes
; Trashes Y
; 32 cycles, including JSR/RTS
.global		switch_mirroring_interruptor

; Constants
DUMMY_REGISTER			:= $4100	; Interrupted register writes are deflected here, along with parity-maintaining writes

.scope	A53
	; Registers
	REGISTER_SELECT		:= $5000
	REGISTER_VALUE		:= $8000

	; Register select values
	.scope	REGISTER_SELECT
		CHR_BANK			= $00
		INNER_BANK			= $01
		MODE				= $80
		OUTER_BANK			= $81
	.endscope

	.scope	MODE
		; Mirroring modes
		ONE_SCREEN_LO		= $00 << 0
		ONE_SCREEN_HI		= $01 << 0
		VERTICAL			= $02 << 0
		HORIZONTAL			= $03 << 0

		; Banking modes
		_32K_BANKABLE		= $00 << 2
		_16K_HI_BANKABLE	= $02 << 2
		_16K_LO_BANKABLE	= $03 << 2

		; Outer bank size
		_32K_OUTER			= $00 << 4
		_64K_OUTER			= $01 << 4
		_128K_OUTER			= $02 << 4
		_256K_OUTER			= $03 << 4
	.endscope

	ONE_SCREEN_LO	= $00 << 4
	ONE_SCREEN_HI	= $01 << 4
.endscope

.endif