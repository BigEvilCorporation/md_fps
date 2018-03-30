;==============================================================
;   MD_FPS - A game by Matt Phillips - (c) 2018
;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   An experimental first-person shooter for SEGA Mega Drive
;==============================================================

; Initial VDP register values
VDPRegisters:
	dc.b 0x14 ; 0:  H interrupt on, palettes on
	dc.b 0x74 ; 1:  V interrupt on, display on, DMA on, Genesis mode on
	dc.b 0x30 ; 2:  Pattern table for Scroll Plane A at VRAM 0xC000 (bits 3-5 = bits 13-15)
	dc.b 0x00 ; 3:  Pattern table for Window Plane at VRAM 0x0000 (disabled) (bits 1-5 = bits 11-15)
	dc.b 0x07 ; 4:  Pattern table for Scroll Plane B at VRAM 0xE000 (bits 0-2 = bits 11-15)
	dc.b 0x78 ; 5:  Sprite table at VRAM 0xF000 (bits 0-6 = bits 9-15)
	dc.b 0x00 ; 6:  Unused
	dc.b 0x00 ; 7:  Background colour - bits 0-3 = colour, bits 4-5 = palette
	dc.b 0x00 ; 8:  Unused
	dc.b 0x00 ; 9:  Unused
	dc.b 0x08 ; 10: Frequency of Horiz. interrupt in Rasters (number of lines travelled by the beam)
	dc.b 0x00 ; 11: External interrupts off, V scroll fullscreen, H scroll fullscreen
	dc.b 0x81 ; 12: Shadows and highlights off, interlace off, H40 mode (320 x 224 screen res)
	dc.b 0x3F ; 13: Horiz. scroll table at VRAM 0xFC00 (bits 0-5)
	dc.b 0x00 ; 14: Unused
	dc.b 0x02 ; 15: Autoincrement 2 bytes
	dc.b 0x01 ; 16: Vert. scroll 32, Horiz. scroll 64
	dc.b 0x00 ; 17: Window Plane X pos 0 left (pos in bits 0-4, left/right in bit 7)
	dc.b 0x00 ; 18: Window Plane Y pos 0 up (pos in bits 0-4, up/down in bit 7)
	dc.b 0xFF ; 19: DMA length lo byte
	dc.b 0xFF ; 20: DMA length hi byte
	dc.b 0x00 ; 21: DMA source address lo byte
	dc.b 0x00 ; 22: DMA source address mid byte
	dc.b 0x80 ; 23: DMA source address hi byte, memory-to-VRAM mode (bits 6-7)
	
	even