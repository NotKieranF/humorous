.include	"perlin.inc"
.include	"math.inc"





.zeropage
perlin_x:		.res 3
perlin_y:		.res 3





.code
; Sample a perlin noise field at the provided input coordinates
;	Takes: Unsigned 16.8-bit input coordinates in perlin_x and perlin_y
;	Returns: Signed 8-bit output in A
;	Clobbers: A, X, Y, $00 - $06
.proc	perlin
	corners		:= $02	; And $03, $04, $05
	angle		:= $06

	LDX #$03
loop:
@permute:
	LDA perlin_x + 1				; This is just an arbitrary way of combining the integer parts of the input coordinates together to produce a pseudo-random number
	CLC
	ADC grid_adjust_x, X
	TAY
	LDA perlin_x + 2
	ADC permutation, Y				; Carry from grid_adjust_x lobyte addition
	TAY
	LDA perlin_y + 1
	CLC
	ADC grid_adjust_y, X
	ADC permutation, Y
	TAY
	LDA perlin_y + 2
	ADC permutation, Y				; Carry from grid_adjust_y lobyte addition

@dot_product:
	; corners[x] = frac(perlin_x) * cos(angle) * (x % 2 == 0 ? 1 : -1)
	STA angle
	CLC
	ADC #$40
	TAY
	LDA trig_table, Y
	TAY

	LDA perlin_x + 0
	EOR grid_invert_x, X
	SET_FAST_MUL_HI
	FAST_MUL_HI
	CPY #$00							; Perform sign correction for multiplier in Y (cosine of angle)
	BPL :+
		SBC fast_mul_sq1_hi_ptr + 0
:	EOR grid_invert_x, X				; Negate X component of dot product when considering gridpoints on the right
	SEC
	SBC grid_invert_x, X
	STA corners, X

	; corners[x] += frac(perlin_y) * sin(angle) * (x < 2 ? 1 : -1)
	LDY angle
	LDA trig_table, Y
	TAY

	LDA perlin_y + 0
	EOR grid_invert_y, X
	SET_FAST_MUL_HI
	FAST_MUL_HI
	CPY #$00							; Perform sign correction for multiplier in Y (sine of angle)
	BPL :+
		SBC fast_mul_sq1_hi_ptr + 0
:	EOR grid_invert_y, X				; Negate Y component of dot product when considering gridpoints on the bottom
	SEC
	SBC grid_invert_y, X
	CLC
	ADC corners, X
	STA corners, X

	DEX
	BPL loop

interpolater:
	; corners[0] = lerp(corners[0], corners[1], frac(perlin_x))
	LDX perlin_x + 0					; Use position within gridcell as an interpolation weight
	LDY smoothstep, X					; Pass our interpolation weight through a smoothing table
	LDX corners + 0
	LDA corners + 1
	JSR signed_interpolate
	STA corners + 0

	; corners[2] = lerp(corners[2], corners[3], frac(perlin_x))
	LDX perlin_x + 0
	LDY smoothstep, X
	LDX corners + 2
	LDA corners + 3
	JSR signed_interpolate
	STA corners + 2

	; return lerp(corners[0], corners[2], frac(perlin_y))
	LDX perlin_y + 0
	LDY smoothstep, X
	LDX corners + 0
	LDA corners + 2
	JSR signed_interpolate
	STA $00
	STA $4444
	RTS

grid_adjust_x:
.byte	$00, $01, $00, $01
grid_adjust_y:
.byte	$00, $00, $01, $01
grid_invert_x:
.byte	$00, $FF, $00, $FF
grid_invert_y:
.byte	$00, $00, $FF, $FF

.endproc

;
;	Takes: a0 in A, a1 in X, w in Y
;	Returns: Interpolated result in A
;	Clobbers:
.proc	interpolate
	a0		:= $00
	a1		:= $01

	STA a0
	STX a1

	LDA a0
	SEC
	SBC a1
	BCC case_2
case_1:
	SET_FAST_MUL_HI
	FAST_MUL_HI
	CLC
	ADC a1
	RTS

case_2:
	LDA a1
	SEC
	SBC a0
	SET_FAST_MUL_HI
	FAST_MUL_HI	
	CLC
	ADC a0
	RTS
.endproc

.proc	signed_interpolate
	a0		:= $00
	a1		:= $01

	STA a0
	STX a1

	LDA a0
	SEC
	SBC a1
	BVC :+
	EOR #$80
:	BMI case_2
case_1:
	BVC :+
	EOR #$80
:	SET_FAST_MUL_HI
	FAST_MUL_HI
	CLC
	ADC a1
	RTS

case_2:
	TYA
	EOR #$FF
	TAY

	LDA a1
	SEC
	SBC a0
	SET_FAST_MUL_HI
	FAST_MUL_HI
	CLC
	ADC a0
	RTS
.endproc





.rodata
smoothstep:
.repeat	256, i
	.byte	((3 * 255 - 2 * i) * i * i) / (255 * 255)		; Smoothstep
.endrep