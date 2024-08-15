.ifndef	MATH_INC
MATH_INC = 1

NUM_PRNG_SEEDS = 1
.globalzp	lfsr_seeds
.global		lfsr_32, permutation
.global		identity_table

; Compute the (co)sine of an angle given in 1/256 revolution angle units
;	Takes: Angle in A
;	Returns: (Co)sine of angle in A
;	Clobbers: A, Y, $00
.global		sin, cos, trig_table

.globalzp	fast_mul_sq1_lo_ptr, fast_mul_sq1_hi_ptr, fast_mul_sq2_lo_ptr, fast_mul_sq2_hi_ptr

; Setup multiplier for inline fast multiplication
;	Takes: 8-bit multiplier in A
;	Returns: Nothing
;	Clobbers: A
.macro	SET_FAST_MUL_HI
	STA fast_mul_sq1_hi_ptr + 0
	EOR #$FF
	STA fast_mul_sq2_hi_ptr + 0
.endmac

; Performs a fast unsigned multiplication
;	Takes: Unsigned 8-bit multiplicand in Y
;	Returns: Signed 8-bit result in A
;	Clobbers: A
.macro	FAST_MUL_HI
	LDA (fast_mul_sq1_hi_ptr), Y
	SEC
	SBC (fast_mul_sq2_hi_ptr), Y
.endmac

; Performs a fast signed multiplication
;	Takes: Signed 8-bit multiplicand in Y
;	Returns: Signed 8-bit result in A
;	Clobbers: A
.macro	SIGNED_FAST_MUL_HI
	.local l1, l2

	LDA (fast_mul_sq1_hi_ptr), Y
	SEC
	SBC (fast_mul_sq2_hi_ptr), Y
	BIT fast_mul_sq1_hi_ptr + 0
	BPL l1
		SEC
		SBC identity_table, Y
l1:	CPY #$00
	BPL l2
		SBC fast_mul_sq1_hi_ptr + 0	; Carry is guaranteed to be set here
l2:
.endmac

.endif