.ifndef	PERLIN_INC
PERLIN_INC = 1

;
;	Takes: 16.8 bit coordinates in perlin_x and perlin_y
;	Returns: 8 bit signed result in A
;	Clobbers: A, X, Y $00 - 
.global		perlin
.globalzp	perlin_x, perlin_y
.global		interpolate, signed_interpolate

.endif