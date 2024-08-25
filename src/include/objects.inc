.ifndef	OBJECTS_INC
OBJECTS_INC = 1

; Maximum number of concurrently loaded objects
MAX_OBJECTS		= 8

; Object parameters
.global		object_id
.global		object_flags
.global		object_state
.global		object_x_lo, object_x_hi	; Unsigned 12.4 bit fixed point
.global		object_y_lo, object_y_hi
.global		object_x_speed				; Signed 4.4 bit fixed point
.global		object_y_speed

.globalzp	camera_x, camera_y
;
;	Takes: object_id in A, object_x_hi in X, object_y_hi in Y
;	Returns: Chosen object slot in X, or $FF if no free slots were found
;	Clobbers:
.global		load_object

; Iterates through object list and 
;	Takes:
;	Returns:
;	Clobbers:
.global		process_objects

;
;
;
;
.global		render_objects

;

.scope	OBJECT
	.scope	FLAGS
		FLIP_V		= %10000000
		FLIP_H		= %01000000
		PRIORITY	= %00100000
	.endscope
.endscope

; Animation opcodes
.enum	ANIM_OPCODE
	LOOP		= $80
	HANG
	JUMP
	SET_STATE
	SET_X_SPEED
	SET_Y_SPEED
	ADD_X_SPEED
	ADD_Y_SPEED
.endenum

.endif