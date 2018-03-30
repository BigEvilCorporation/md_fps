;==============================================================
;   MD_FPS - A game by Matt Phillips - (c) 2018
;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   An experimental first-person shooter for SEGA Mega Drive
;==============================================================

; VDP port addresses
vdp_control				equ 0x00C00004
vdp_data				equ 0x00C00000

; VDP commands
vdp_cmd_vram_write		equ 0x40000000
vdp_cmd_cram_write		equ 0xC0000000
vdp_cmd_vsram_write		equ 0x40000010

; VDP memory addresses
vram_addr_tiles			equ 0x0000
vram_addr_plane_a		equ 0xC000
vram_addr_plane_b		equ 0xE000
vram_addr_sprite_table	equ 0xF000
vram_addr_hscroll		equ 0xFC00

; Screen size
vdp_screen_width		equ 0x0140
vdp_screen_height		equ 0x00E0
vdp_plane_width			equ 0x0040
vdp_plane_height		equ 0x0020

; Hardware version address
hardware_ver_address	equ 0x00A10001

; TMSS
tmss_address			equ 0x00A14000
tmss_signature			equ 'SEGA'

; Sizes
size_word				equ 2
size_long				equ 4

; The size of one palette (in bytes, words, and longwords)
size_palette_b			equ 0x10
size_palette_w			equ size_palette_b*2
size_palette_l			equ size_palette_b*4

; The size of one graphics tile (in bytes, words, and longwords)
size_tile_b				equ 0x20
size_tile_w				equ size_tile_b*2
size_tile_l				equ size_tile_b*4

; Gamepad ports
pad_data_a              equ 0x00A10003
pad_data_b              equ 0x00A10005
pad_data_c              equ 0x00A10007
pad_ctrl_a              equ 0x00A10009
pad_ctrl_b              equ 0x00A1000B
pad_ctrl_c              equ 0x00A1000D

pad_byte_latch			equ 0x40

pad_button_up           equ 0x0
pad_button_down         equ 0x1
pad_button_left         equ 0x2
pad_button_right        equ 0x3
pad_button_a            equ 0xC
pad_button_b            equ 0x4
pad_button_c            equ 0x5
pad_button_start        equ 0xD

pad_button_all			equ 0x303F