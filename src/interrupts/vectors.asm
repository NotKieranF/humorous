.include	"rst.inc"
.include	"nmi.inc"
.include	"irq.inc"



.segment "VECTORS"
.word	nmi
.word	rst
.word	irq