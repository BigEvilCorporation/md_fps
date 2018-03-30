;==============================================================
;   MD_FPS - A game by Matt Phillips - (c) 2018
;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   An experimental first-person shooter for SEGA Mega Drive
;==============================================================

; VDP data port setup macros
SetVRAMWrite: macro addr
	move.l  #(vdp_cmd_vram_write)|((\addr)&$3FFF)<<16|(\addr)>>14, vdp_control
    endm
	
SetVSRAMWrite: macro addr
	move.l  #(vdp_cmd_vsram_write)|((\addr)&$3FFF)<<16|(\addr)>>14, vdp_control
    endm
	
SetCRAMWrite: macro addr
	move.l  #(vdp_cmd_cram_write)|((\addr)&$3FFF)<<16|(\addr)>>14, vdp_control
    endm

; Set VDP data address for reading/writing
VDP_SETADDRESS: macro destreg, baseaddr, optype
	; Address bit pattern: --DC BA98 7654 3210 ---- ---- ---- --FE
	add.l   \baseaddr, \destreg		; Add VRAM address offset
	rol.l   #0x2,\destreg			; Roll bits 14/15 of address to bits 16/17
	lsr.w   #0x2, \destreg			; Shift lower word back
	swap    \destreg				; Swap address hi/lo
	ori.l   \optype, \destreg		; OR in VRAM/CRAM/VSRAM write/read command
	move.l  \destreg, vdp_control	; Move dest address to VDP control port
	endm

;==============================================================

; Stack push (word)
PUSHW: macro reg
    move.w \reg, -(sp)
    endm
	
; Stack pop (word)
POPW: macro reg
    move.w (sp)+, \reg
    endm
	
; Stack push (longword)
PUSHL: macro reg
    move.l \reg, -(sp)
    endm
	
; Stack pop (longword)
POPL: macro reg
    move.l (sp)+, \reg
    endm

; Stack push multiple regs (word)
PUSHMW: macro regs
	 movem.w \regs, -(sp)
	 endm
	 
; Stack pop multiple regs (word)
POPMW: macro regs
	movem.w (sp)+, \regs
	endm

; Stack push multiple regs (longword)
PUSHM: macro regs
	 movem.l \regs, -(sp)
	 endm
	 
; Stack pop multiple regs (longword)
POPM: macro regs
	movem.l (sp)+, \regs
	endm
	
; Stack push all regs
PUSHALL: macro
	 movem.l d0-d7/a0-a6, -(sp)
	 endm
	 
; Stack pop all regs
POPALL: macro
	movem.l (sp)+, d0-d7/a0-a6
	endm