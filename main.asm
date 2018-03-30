;==============================================================
;   MD_FPS - A game by Matt Phillips - (c) 2018
;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   An experimental first-person shooter for SEGA Mega Drive
;==============================================================

ROM_Start

	include 'header.asm'
	include 'vdpregs.asm'
	include 'constants.asm'
	include 'macros.asm'
	include 'maths.asm'
	include 'tiles.asm'
	include 'palettes.asm'
	include 'cols.asm'
	include 'map.asm'
	include 'ang2vec.asm'
	include 'gamepad.asm'
	
;==============================================================

TestColumnHeights:
	dc.b 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
	even

TestColumnHeights2:
	dc.b 0,1,2,3,4,5,6,7,40,40,40,40,40,40,14,15,16,17,18,19,20,19,18,17,16,15,14,20,21,22,23,24,25,7,6,5,4,3,2,1,0
	even

fisheye_fudge:
	dc.b 0,1,2,3,4,5,6,7,8,8,8,8,8,9,9,10,10,10,10,10,10,10,10,10,10,9,9,8,8,8,8,8,7,6,5,4,3,2,1,0

num_palettes			equ 2
num_tiles				equ 10
bg_palette_max_shades	equ 6
visibility_plane_size	equ (vdp_screen_width/8)*(vdp_screen_height/8)
column_height			equ 16	; Columns are 16 tiles high
column_draw_height		equ ((vdp_screen_height/8)/2)+1	; Draw half column, flip for bottom half
max_draw_distance		equ (column_height-1)*8		; Max number of column height variations
player_view_fov			equ 0x00010000				; 90 degrees
player_cam_plane_dist	equ 0x00040000				; Distance from player to camera plane
raycast_check_step		equ 0x00008000				; Check very half grid square for wall
cam_plane_width			equ (vdp_screen_width/8)	; Camera plane width (num draw columns)

; Movement
player_turn_speed		equ 0x4<<8

;==============================================================

; Memory map (named offsets from start of RAM)
	rsset 0x00FF0000
ram_column_height_idxs	rs.b cam_plane_width
ram_vblank_counter		rs.l 1
ram_player_pos_x		rs.l 1
ram_player_pos_y		rs.l 1
ram_player_angle		rs.w 1

;==============================================================

Raycast:
	; d0 (l) X pos
	; d1 (l) Y pos
	; d2 (b) Angle
	; d3 (l) OUT: distance to wall, or 0

	; Init distance
	moveq  #0x0, d3

	; Get direction from angle table
	andi.l #0xFF, d2
	lsl.l  #0x3, d2		; 2x longs(X/Y)  per table entry
	lea    ang2vec1616_table, a0
	add.l  d2, a0

	move.l (a0)+, d4	; X direction
	move.l (a0)+, d5	; Y direction

	; Search until hit wall
	@RaycastLp:

	PUSHM  d0-d1
	swap   d0				; X pos (integer)
	move.w #0x0, d1
	swap   d1				; Y pos (integer)
	mulu   #map_width, d1	; Y * map width
	add.w  d0, d1			; + X
	lea    map, a2			; Get map
	add.l  d1, a2			; Add offset
	move.b (a2), d4			; Get map cell
	POPM   d0-d1

	; Increment distance
	addi.l #0x00010000, d3

	; Advance position
	add.l  d4, d0
	add.l  d5, d1

	tst.b  d4				; Check if hit wall
	beq    @RaycastLp

	rts

;==============================================================

	; The "main()" function
CPU_EntryPoint:

	;==============================================================
	; Initialise the Mega Drive
	;==============================================================

	; Write the TMSS signature (if a model 1+ Mega Drive)
	jsr VDP_WriteTMSS
	
	; Load the initial VDP registers
	jsr VDP_LoadRegisters

	; Clear VRAM
	SetVRAMWrite 0x0000
	move.w #(0x00010000/size_word)-1, d0
	@ClrVramLp:
	move.w #0x0, vdp_data
	dbra   d0, @ClrVramLp

	; Init scroll
	SetVRAMWrite vram_addr_hscroll
	move.w #0x0, vdp_data
	SetVSRAMWrite 0x0000
	move.w #0x0, vdp_data
	
	;==============================================================
	; Initialise variables in RAM
	;==============================================================
	move.l #(map_width/2)<<16, ram_player_pos_x
	move.l #(map_height/2)<<16, ram_player_pos_y
	move.b #0x0, ram_player_angle

	; Write test data
	lea    ram_column_height_idxs, a0
	lea    TestColumnHeights2, a1
	move.w #vdp_screen_width/8, d0
	@WriteColHeightsLp:
	move.b (a1)+, (a0)+
	dbra   d0, @WriteColHeightsLp

	IF 0

	; Angle to vector
	andi.l #0xFF, d2
	lsl.l  #0x3, d2		; 2x longs(X/Y)  per table entry
	lea    ang2vec1616_table, a0
	lea    ang2vec1616_table_90, a1
	add.l  d2, a0
	add.l  d2, a1
	move.l (a0)+, d2	; X player direction
	move.l (a0)+, d3	; Y player direction
	move.l (a1)+, d4	; X direction along camera plane
	move.l (a1)+, d5	; Y direction along camera plane

	; Project forward from player pos to camera plane
	PUSHM  d0-d5
	move.l d4, d0						; X direction * camera plane dist
	move.l #player_cam_plane_dist, d1
	jsr    Muls1616
	move.l d0, d6						; To d6
	POPM   d0-d5

	PUSHM  d0-d6
	move.l d5, d0						; Y direction * camera plane dist
	move.l #player_cam_plane_dist, d1
	jsr    Muls1616
	move.l d0, d7						; To d7
	POPM   d0-d6

	add.l  d0, d6						; Camera plane centre X
	add.l  d1, d7						; Camera plane centre Y

	; TODO: Rotate camera plane vector

	; Get camera plane left pos
	PUSHM  d0-d1
	move.l d4, d0						; Cam plane vector X
	move.l #(cam_plane_width/2)<<16, d1	; Cam plane half length
	PUSHM  d1-d7
	jsr    Muls1616
	POPM   d1-d7
	sub.l  d0, d6						; Cam plane left pos X
	POPM   d0-d1

	PUSHM  d0-d1
	move.l d5, d0						; Cam plane vector Y
	move.l #(cam_plane_width/2)<<16, d1	; Cam plane half length
	PUSHM  d1-d7
	jsr    Muls1616
	POPM   d1-d7
	sub.l  d0, d7						; Cam plane left pos Y
	POPM   d0-d1

	; Walk along camera plane, detecting walls between player pos and plane pos
	move.w #cam_plane_width-1, d2
	@WallSearchLp:

	; d0 (l) From X
	; d1 (l) From Y
	; d6 (l) To X
	; d7 (l) To Y
	; d0 (l) Wall distance or 0
	jsr    Raycast
	
	@RaycastLp:

	add.l  d4, d6	; Advance pos along camera plane
	add.l  d5, d7
	dbra   d2, @WallSearchLp

	ENDIF

	;==============================================================
	; Initialise status register and set interrupt level
	;==============================================================
	move.w #0x2300, sr
	
	;==============================================================
	; Write a palette to colour memory
	;==============================================================
	
	; Setup the VDP to write to CRAM address 0x0000 (first palette)
	SetCRAMWrite 0x0000
	
	; Write the palettes
	lea    Palette, a0				; Move palette address to a0
	move.w #(num_palettes*size_palette_w)-1, d0	; Loop counter = 8 words in palette (-1 for DBRA loop)
	@PalLp:							; Start of loop
	move.w (a0)+, vdp_data			; Write palette entry, post-increment address
	dbra d0, @PalLp					; Decrement d0 and loop until finished (when d0 reaches -1)
	
	;==============================================================
	; Write the font to tile memory
	;==============================================================
	
	; Setup the VDP to write to VRAM address 0x0000 (the address of the first graphics tile)
	SetVRAMWrite 0x0000
	
	; Write the tiles
	lea    Tiles, a0							; Move the address of the first graphics tile into a0
	move.w #(num_tiles*size_tile_l)-1, d0		; Loop counter = 8 longwords per tile (-1 for DBRA loop)
	@CharLp:									; Start of loop
	move.l (a0)+, vdp_data						; Write tile line (4 bytes per line), post-increment address
	dbra d0, @CharLp							; Decrement d0 and loop until finished (when d0 reaches -1)
	
	;==============================================================
	; Setup BG gradiant
	;==============================================================

	IF 0

	move.w #(vdp_screen_width/8)-1, d1		; Screen width in cols
	@BgColLp:
	moveq  #0x0, d0
	move.w d1, d0							; Plane B column offset
	lsl.w  #0x1, d0							; To words

	; Half screen height
	move.w #(vdp_screen_width/8/2)-1, d2
	@BgTopRowLp:
	move.w #(vdp_screen_width/8/2), d4		; Invert row counter for shade idx
	sub.w  d2, d4
	CLAMPW d4,#0x0,#bg_palette_max_shades	; Clamp to max gradiant shades in palette
	move.w #(1<<13), d3						; Palette
	move.b d4, d3							; Tile ID

	; Top half of screen
	PUSHL  d0
	VDP_SETADDRESS d0, #vram_addr_plane_b, #vdp_cmd_vram_write
	POPL   d0
	move.w d3, vdp_data

	; Bottom half of screen
	move.l #(vdp_plane_width*size_word)*(vdp_screen_height/8), d5	; Invert plane B row address
	sub.w  d0, d5
	VDP_SETADDRESS d5, #vram_addr_plane_b, #vdp_cmd_vram_write
	move.w d3, vdp_data

	addi.w #(vdp_plane_width*size_word), d0	; Next row
	dbra   d2, @BgTopRowLp

	dbra   d1, @BgColLp

	ENDIF
	
	;==============================================================
	; Loop forever
	;==============================================================
	@MainLoop:

	; Get gamepad input
	jsr Input

	; Compute draw columns
	jsr Process

	; Wait for next VINT
	move.l ram_vblank_counter, d0
	@WaitForVINT:
	move.l ram_vblank_counter, d1
	cmp.l  d0, d1
	beq    @WaitForVINT

	; Render
	jsr Output

	bra @MainLoop
	
;==============================================================

Input:

	jsr    PAD_ReadPadA

	btst   #pad_button_left, d0
	bne    @NoLeft
	addi.w #player_turn_speed, ram_player_angle	; Turn left
	@NoLeft:

	btst   #pad_button_right, d0
	bne    @NoRight
	subi.w #player_turn_speed, ram_player_angle	; Turn right
	@NoRight:

	; Get player pos
	move.l ram_player_pos_x, d2
	move.l ram_player_pos_y, d3

	; Get direction from angle table
	move.b ram_player_angle, d6
	andi.l #0xFF, d6
	lsl.l  #0x3, d6					; 2x longs(X/Y)  per table entry
	lea    ang2vec1616_table, a0
	add.l  d6, a0
	move.l (a0)+, d4				; X direction
	move.l (a0)+, d5				; Y direction

	btst   #pad_button_up, d0
	bne    @NoUp
	sub.l  d4, d2					; Move forward
	sub.l  d5, d3
	@NoUp:

	btst   #pad_button_a, d0
	bne    @NoA
	sub.l  d4, d2					; Move forward
	sub.l  d5, d3
	@NoA:

	btst   #pad_button_down, d0
	bne    @NoDown
	add.l  d4, d2					; Move backward
	add.l  d5, d3
	@NoDown:

	btst   #pad_button_b, d0
	bne    @NoB
	add.l  d4, d2					; Move backward
	add.l  d5, d3
	@NoB:

	; Clamp player pos to map bounds
	swap   d2
	swap   d3
	CLAMPW d2, #0x1, #map_width-1
	CLAMPW d3, #0x1, #map_height-1
	swap   d2
	swap   d3

	move.l d2, ram_player_pos_x
	move.l d3, ram_player_pos_y

	rts

;==============================================================

Process:

	; Get player pos and angle
	move.l ram_player_pos_x, d0
	move.l ram_player_pos_y, d1
	move.b ram_player_angle, d2

	; Search from angle-(screen_width/2) to angle+(screen_width/2)
	sub.b  #cam_plane_width/2, d2
	move.w #cam_plane_width-1, d3
	lea    fisheye_fudge, a5
	lea    ram_column_height_idxs, a6
	@RaycastLp:
	PUSHM  d0-d3
	jsr    Raycast		; Raycast from player pos towards angle
	swap   d3			; Wall distance to array
	lsl.w  #0x1, d3		; Scale wall
	;add.b  (a5)+, d3	; Correct for fisheye
	CLAMPW d3, #0x0, #max_draw_distance-1	; Clamp distance
	move.b d3, (a6)+
	POPM   d0-d3
	addi.b #0x1, d2		; Next angle
	dbra   d3, @RaycastLp
	
	rts

;==============================================================

Output:

	; Loop columns
	lea    ram_column_height_idxs, a0	; Get column map from RAM
COL_INDEX = 0
	REPT   (vdp_screen_width/8)
	moveq  #0x0, d0
	move.b (a0)+, d0					; Get next column index
	lsl.w  #0x5, d0						; To column offset (16 words per column)
	lea    Columns, a1					; Get columns
	add.l  d0, a1						; Add offset

	; Loop rows
ROW_INDEX = 0
	REPT   column_draw_height
	SetVRAMWrite vram_addr_plane_a+(vdp_plane_width*ROW_INDEX*size_word)+(COL_INDEX*size_word)	; Get column dest address in VRAM
	move.w (a1)+, vdp_data	; Write cell idx word
ROW_INDEX = ROW_INDEX+1
	ENDR

	; Mirror for bottom half of screen
	REPT   column_draw_height
	SetVRAMWrite vram_addr_plane_a+(vdp_plane_width*ROW_INDEX*size_word)+(COL_INDEX*size_word)	; Get column dest address in VRAM
	move.w -(a1), d1				; Get tile idx
	ori.w  #%0001000000000000, d1	; Flip Y
	move.w d1, vdp_data				; Write cell idx word
ROW_INDEX = ROW_INDEX+1
	ENDR

COL_INDEX = COL_INDEX+1
	ENDR

	rts

	;==============================================================

INT_VBlank:

	; Tick
	addi.l #0x1, ram_vblank_counter

	rte

INT_HBlank:
	rte

INT_Null:
	rte

CPU_Exception:
	stop   #0x2700
	rte
	
;==============================================================
	
VDP_WriteTMSS:

	move.b hardware_ver_address, d0			; Move Megadrive hardware version to d0
	andi.b #0x0F, d0						; The version is stored in last four bits, so mask it with 0F
	beq @Skip								; If version is equal to 0, skip TMSS signature
	move.l #tmss_signature, tmss_address	; Move the string "SEGA" to 0xA14000
	@Skip:

	; Check VDP
	move.w vdp_control, d0					; Read VDP status register (hangs if no access)
	
	rts
	
VDP_LoadRegisters:

	; Set VDP registers
	move.l #VDPRegisters, a0	; Load address of register init table into a0
	move.w #0x17, d0			; 24 registers to write (-1 for loop counter)
	move.w #0x8000, d1			; 'Set register 0' command

	@CopyVDP:
	move.b (a0)+, d1			; Move register value to lower byte of d1
	move.w d1, vdp_control		; Write command and value to VDP control port
	add.w  #0x0100, d1			; Increment register #
	dbra   d0, @CopyVDP
	
	rts
	
ROM_End