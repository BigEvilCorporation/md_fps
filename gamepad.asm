;==============================================================
;   MD_FPS - A game by Matt Phillips - (c) 2018
;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   An experimental first-person shooter for SEGA Mega Drive
;==============================================================

PAD_Init:
	move.b #pad_byte_latch, pad_ctrl_a  ; Controller port 1 CTRL
	move.b #pad_byte_latch, pad_ctrl_b  ; Controller port 2 CTRL
	rts
	
PAD_ReadPadA:
	; d0 (w) - Pad A return result (00SA0000 00CBRLDU)
	
	move.b  #0x0, pad_data_a   ; Set port to read byte 0
	nop						   ; 2-NOP delay to respond to change
	nop
	move.b  pad_data_a, d0     ; Read byte
	rol.w   #0x8, d0           ; Move to upper byte of d0
	move.b  #pad_byte_latch, pad_data_a  ; Set port to read byte 1
	nop						   ; 2-NOP delay to respond to change
	nop
	move.b  pad_data_a, d0     ; Read byte
	
	; Invert and mask
	neg.w   d0
	subq.w   #0x1, d0
	andi.w  #pad_button_all, d0

	rts