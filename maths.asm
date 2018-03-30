;==============================================================
;   MD_FPS - A game by Matt Phillips - (c) 2018
;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   An experimental first-person shooter for SEGA Mega Drive
;==============================================================

CLAMPW: macro valuereg,minreg,maxreg
	cmp.w  \minreg,\valuereg
	bge    @WITHIN_MIN\@
	move.w \minreg,\valuereg
	@WITHIN_MIN\@:
	cmp.w  \maxreg,\valuereg
	ble    @WITHIN_MAX\@
	move.w \maxreg,\valuereg
	@WITHIN_MAX\@:
	endm

CLAMPL: macro valuereg,minreg,maxreg
	cmp.l  \minreg,\valuereg
	bge    @WITHIN_MIN\@
	move.l \minreg,\valuereg
	@WITHIN_MIN\@:
	cmp.l  \maxreg,\valuereg
	ble    @WITHIN_MAX\@
	move.l \maxreg,\valuereg
	@WITHIN_MAX\@:
	endm

ABSL: macro valuereg
	cmp.l #0x0, \valuereg
	bge   @Pos\@
	neg.l \valuereg
	@Pos\@:
	endm

;==============================================================

; Fixed point unsigned 16.16 multiply
Mulu1616:
	; d0 (l) Operand a
	; d1 (l) Operand b
	; d0 (l) OUT: Result

	; a = x >> 16;
	; b = x & 0xffff;
	; c = y >> 16;
	; d = y & 0xffff;

	PUSHM  d2-d6

	moveq  #0x0, d2
	moveq  #0x0, d3
	move.w d0, d2	; b
	move.w d1, d3	; d
	clr.w  d0
	swap   d0		; a
	clr.w  d1
	swap   d1		; c

	; ((d * b) >> 16) + (d * a) + (c * b) + ((c * a) << 16)

	; d0 = a
	; d2 = b
	; d1 = c
	; d3 = d

	; ((d * b) >> 16)
	move.l d2, d4
	mulu   d3, d4
	clr.w  d4
	swap   d4

	; (d * a)
	move.l d0, d5
	mulu   d3, d5

	; (c * b)
	move.l d2, d6
	mulu   d1, d6

	; ((c * a) << 16)
	mulu   d1, d0
	swap   d0
	clr.w  d0

	add.l  d4, d0
	add.l  d5, d0
	add.l  d6, d0

	POPM   d2-d6

	rts

; Fixed point unsigned 16.16 multiply
Muls1616:
	; d0 (l) Operand a
	; d1 (l) Operand b
	; d0 (l) OUT: Result

	move.l d0, d2
	PUSHL d2
	ABSL  d0			; Mul unsigned
	jsr   Mulu1616
	POPL  d2
	tst.l d2			; Restore sign
	bge   @Pos
	neg.l d0
	@Pos:

	rts
