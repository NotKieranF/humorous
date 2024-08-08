.include	"mapper.inc"
.constructor	init_mapper





.zeropage
current_mirroring:				.res 1
current_chr_bank:				.res 1
current_prg_bank:				.res 1
semaphore_ptr:					.res 2	; Interrupts should set the high byte of this pointer to $40 if they interact with banking registers to deflect writes from the main thread





.code
; Switches the 16KiB bank at CPU $8000 based on the value in A in an interrupt safe manner
;	Takes: Bank ID to switch to in A
;	Returns: Nothing
;	Clobbers: A, Y
.proc	switch_prg_bank_interruptable
	STA current_prg_bank

	LDA #>identity_table						; Set high byte of semaphore_ptr to point to a bus conflict avoidance table
	STA semaphore_ptr + 1

	LDA current_prg_bank
	ORA current_mirroring

	TAY											; If we haven't been interrupted, then the pointer still points to the register we want to access
	STA (semaphore_ptr), Y						; If we have, then the pointer will point to $4100 and the write will have no effect

	RTS
.endproc

; Switches the 16KiB bank at CPU $8000 based on the value in A. Doesn't deflect writes, but should be used in interrupt handlers and should not be used elsewhere
;	Takes: Bank ID to switch to in A
;	Returns: Nothing
;	Clobbers: A, Y
.proc	switch_prg_bank_interruptor
	ORA current_mirroring

	TAY
	STA identity_table, Y

	RTS
.endproc

; Switches the 8KiB bank at PPU $0000 based on the value in A, deflecting any interrupted writes
;	Takes: Bank ID to switch to in A
;	Returns: Nothing
;	Clobbers: A, Y
.proc	switch_chr_bank_interruptor
	LDY #A53::REGISTER_SELECT::CHR_BANK
	STY A53::REGISTER_SELECT
	
	STA current_chr_bank
	ORA current_mirroring

	TAY
	STA identity_table, Y

	LDA #>DUMMY_REGISTER						; Deflect any interrupted register writes as we have the most up-to-date values
	STA semaphore_ptr + 1

	LDY #A53::REGISTER_SELECT::INNER_BANK		; Restore assumed register state
	STY A53::REGISTER_SELECT

	RTS
.endproc

; Switches the mirroring mode based on the value in A, deflecting any interrupted writes
;	Takes: Mirroring type to switch to in A
;	Returns: Nothing
;	Clobbers: A, Y
.PROC	switch_mirroring_interruptor
	STA current_mirroring
	ORA current_prg_bank

	TAY
	STA identity_table, Y

	LDA #>DUMMY_REGISTER		; Deflect any interrupted register writes as we have the most up-to-date values
	STA semaphore_ptr + 1

	RTS
.ENDPROC

; One time mapper initializaton
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A
.proc	init_mapper
	LDA #<identity_table						; Set high byte of semaphore_ptr to point to a bus conflict avoidance table
	STA semaphore_ptr + 0

	LDA #A53::REGISTER_SELECT::OUTER_BANK		; Setup outer bank register, need not be done when included in a multicart
	STA A53::REGISTER_SELECT
	LDA #$FF
	STA A53::REGISTER_VALUE

	LDA #A53::REGISTER_SELECT::MODE				; Setup mirroring and banking modes
	STA A53::REGISTER_SELECT
	LDA #A53::MODE::ONE_SCREEN_LO | A53::MODE::_64K_OUTER | A53::MODE::_16K_LO_BANKABLE
	STA A53::REGISTER_VALUE

	LDA #A53::REGISTER_SELECT::INNER_BANK		; Inner bank is the assumed register select state
	STA A53::REGISTER_SELECT

	RTS
.endproc





.rodata
identity_table:
.repeat	256, i
	.byte	i
.endrep