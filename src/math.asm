.include	"math.inc"
.constructor	init_math





.zeropage
lfsr_seeds:				.res 4 * NUM_PRNG_SEEDS
fast_mul_sq1_lo_ptr:	.res 2
fast_mul_sq1_hi_ptr:	.res 2
fast_mul_sq2_lo_ptr:	.res 2
fast_mul_sq2_hi_ptr:	.res 2





.code
permutation:
.BYTE	151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36 
.BYTE	103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0
.BYTE	26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56
.BYTE	87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166
.BYTE	77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55
.BYTE	46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132
.BYTE	187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109
.BYTE	198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126
.BYTE	255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183
.BYTE	170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43
.BYTE	172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112
.BYTE	104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162
.BYTE	241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106
.BYTE	157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205
.BYTE	93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
; Generate an 8-bit random number based on a 32 bit seed (Taken from: https://www.nesdev.org/wiki/Random_number_generator/Linear_feedback_shift_register_(advanced))
;	Takes: Seed index in X
;	Returns: Random 8-bit number in A
;	Clobbers: A, Y
.proc	lfsr_32
	LDA lfsr_seeds + 0
	LDY lfsr_seeds + 1
	CLC
	ADC permutation, Y
	TAY
	LDA lfsr_seeds + 2
	ADC permutation, Y
	TAY
	LDA lfsr_seeds + 3
	ADC permutation, Y

	RTS


	; rotate the middle bytes left
	LDY lfsr_seeds + 2 ; will move to lfsr_seeds + 3 at the end
	LDA lfsr_seeds + 1
	STA lfsr_seeds + 2
	; compute lfsr_seeds + 1 ($C5>>1 = %1100010)
	LDA lfsr_seeds + 3 ; original high byte
	LSR
	STA lfsr_seeds + 1 ; reverse: 100011
	LSR
	LSR
	LSR
	LSR
	EOR lfsr_seeds + 1
	LSR
	EOR lfsr_seeds + 1
	EOR lfsr_seeds + 0 ; combine with original low byte
	STA lfsr_seeds + 1
	; compute lfsr_seeds + 0 ($C5 = %11000101)
	LDA lfsr_seeds + 3 ; original high byte
	ASL
	EOR lfsr_seeds + 3
	ASL
	ASL
	ASL
	ASL
	EOR lfsr_seeds + 3
	ASL
	ASL
	EOR lfsr_seeds + 3
	STY lfsr_seeds + 3 ; finish rotating byte 2 into 3
	STA lfsr_seeds + 0
	RTS
.endproc

; Compute the cosine of an angle given in 1/256 revolution angle units
;	Takes: Angle in A
;	Returns: Cosine of angle in A
;	Clobbers: A, X, $00
.proc	cos
	CLC						; Perform 90 degree phase shift of angle before falling through into sin routine
	ADC #$40
	.assert * = sin, error, "cos routine must fall through into sin"
.endproc

; Compute the sine of an angle given in 1/256 revolution angle units
;	Takes: Angle in A
;	Returns: Sine of angle in A
;	Clobbers: A, X, $00
.proc	sin
	temp			:= $00

	STA temp
	BIT temp				; V flag now indicates whether we're in the first/third, or second/fourth quadrants
	BVC :+
		EOR #$FF			; If we're in the second or fourth quadrant, we need to invert our index into the table to flip along the y-axis
:	AND #%00111111			; Mask off higher order bits to index into quarter length trig table
	TAY
	LDA trig_table, Y
	BIT temp				; N flag now indicates whether we're in the first/second, or third/fourth quadrants
	BPL :+
		EOR #$FF			; If we're in the third or fourth quadrant, we need to negate the output to flip along the x-axis
		CLC
		ADC #$01
:	RTS
.endproc

; Interpolate between two unsigned 8-bit values
;	Takes: Unsigned 8-bit base value in A, unsigned 8-bit target value in X, unsigned 8-bit interpolation weight in Y
;	Returns: Unsigned 8-bit interpolated result in A
;	Clobbers: A, X, Y, $00 - $01
.proc	interpolate
	a0			:= $00
	a1			:= $01

	STA a0
	STX a1

;	LDA a0
	SEC
	SBC a1
	BCC case_2						; Split into two separate cases due to the fact that this subtraction can result in an underflow
; (a0 - a1) * w + a1
case_1:
	STA fast_mul_sq1_hi_ptr + 0		; Setup fast mul pointers
	EOR #$FF
	CLC
	ADC #$01
	STA fast_mul_sq2_hi_ptr + 0
	FAST_MUL_HI
	CLC
	ADC a1

	RTS

; (a1 - a0) * (1 - w) + a0
case_2:
	STA fast_mul_sq2_hi_ptr + 0		; Setup fast mul pointers in *reverse* order, as we already have a negative result from the original subtraction
	EOR #$FF
	CLC
	ADC #$01
	STA fast_mul_sq1_hi_ptr + 0

	TYA								; Get (1 - w) for our new interpolation weight, since we've effectively switched the order of our interpolation parameters
	EOR #$FF
	TAY
	FAST_MUL_HI
	CLC
	ADC a0

	RTS
.endproc

;
;	Takes: Signed 8-bit base value in A, signed 8-bit target value in X, unsigned 8-bit interpolation weight in Y
;	Returns: Signed 8-bit interpolated result in A
;	Clobbers: A, X, Y, $00 - $01
.proc	signed_interpolate

.endproc

; Initialize fastmul pointers and prng seeds
;	Takes: Nothing
;	Returns: Nothing
;	Clobbers: A, X
.proc	init_math
	LDA #>fast_mul_sq1_lo
	STA fast_mul_sq1_lo_ptr + 1
	LDA #>fast_mul_sq1_hi
	STA fast_mul_sq1_hi_ptr + 1
	LDA #>fast_mul_sq2_lo
	STA fast_mul_sq2_lo_ptr + 1
	LDA #>fast_mul_sq2_hi
	STA fast_mul_sq2_hi_ptr + 1

	LDA #$FF
	LDX #4 * NUM_PRNG_SEEDS - 1
:	STA lfsr_seeds, X
	DEX
	BPL :-

	RTS
.endproc





.rodata
; Quarter sine table for computing sine and cosine
.align	256
trig_table:
.byte	$00, $03, $06, $09, $0C, $10, $13, $16, $19, $1C, $1F, $22, $25, $28, $2B, $2E
.byte	$31, $33, $36, $39, $3C, $3F, $41, $44, $47, $49, $4C, $4E, $51, $53, $55, $58
.byte	$5A, $5C, $5E, $60, $62, $64, $66, $68, $6A, $6B, $6D, $6F, $70, $71, $73, $74
.byte	$75, $76, $78, $79, $7A, $7A, $7B, $7C, $7D, $7D, $7E, $7E, $7E, $7F, $7F, $7F
.byte	$7F, $7F, $7F, $7F, $7E, $7E, $7E, $7D, $7D, $7C, $7B, $7A, $7A, $79, $78, $76
.byte	$75, $74, $73, $71, $70, $6F, $6D, $6B, $6A, $68, $66, $64, $62, $60, $5E, $5C
.byte	$5A, $58, $55, $53, $51, $4E, $4C, $49, $47, $44, $41, $3F, $3C, $39, $36, $33
.byte	$31, $2E, $2B, $28, $25, $22, $1F, $1C, $19, $16, $13, $10, $0C, $09, $06, $03
.byte	$00, $FD, $FA, $F7, $F4, $F0, $ED, $EA, $E7, $E4, $E1, $DE, $DB, $D8, $D5, $D2
.byte	$CF, $CD, $CA, $C7, $C4, $C1, $BF, $BC, $B9, $B7, $B4, $B2, $AF, $AD, $AB, $A8
.byte	$A6, $A4, $A2, $A0, $9E, $9C, $9A, $98, $96, $95, $93, $91, $90, $8F, $8D, $8C
.byte	$8B, $8A, $88, $87, $86, $86, $85, $84, $83, $83, $82, $82, $82, $81, $81, $81
.byte	$81, $81, $81, $81, $82, $82, $82, $83, $83, $84, $85, $86, $86, $87, $88, $8A
.byte	$8B, $8C, $8D, $8F, $90, $91, $93, $95, $96, $98, $9A, $9C, $9E, $A0, $A2, $A4
.byte	$A6, $A8, $AB, $AD, $AF, $B2, $B4, $B7, $B9, $BC, $BF, $C1, $C4, $C7, $CA, $CD
.byte	$CF, $D2, $D5, $D8, $DB, $DE, $E1, $E4, $E7, $EA, $ED, $F0, $F4, $F7, $FA, $FD

; Square tables for fast mul routine
fast_mul_sq2_lo:
.repeat 512, i
	.lobytes	((i - 255) * (i - 255)) / 4
.endrep
fast_mul_sq1_lo:
.repeat	512, i
	.lobytes	(i * i) / 4
.endrep

fast_mul_sq2_hi:
.repeat	512, i
	.hibytes	((i - 255) * (i - 255)) / 4
.endrep
fast_mul_sq1_hi:
.repeat	512, i
	.hibytes	(i * i) / 4
.endrep

; Identity table for performing inter-register operations, or avoiding bus conflicts
identity_table:
.repeat	256, i
	.byte	i
.endrep