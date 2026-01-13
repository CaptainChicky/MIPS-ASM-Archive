# Display Driver
# =================================================================================================
# This driver provides functions for operations involving multiple loads/stores or non-obvious
# sequences that benefit from abstraction. Single load/store operations are accessed directly.

	.include "displayVariables.asm"
	.include "displayConstants.asm"
	.include "macros.asm"

# =================================================================================================
# Display Control and Frame Synchronization
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# void display_init(int msPerFrame, bool enableFB, bool enableTM)
# -------------------------------------------------------------------------------------------------
# Initialize the display, switch to enhanced mode, and reset everything.
#
# Arguments:
#   a0 - milliseconds per frame (determines frame rate)
#   a1 - enable framebuffer (0 = disabled, non-zero = enabled)
#   a2 - enable tilemap (0 = disabled, non-zero = enabled)
display_init:
	# Shift ms per frame into proper position
	sll a0, a0, DISPLAY_MODE_MS_SHIFT

	# Conditionally enable framebuffer
	beq a1, 0, _no_fb
	or a0, a0, DISPLAY_MODE_FB_ENABLE

_no_fb:
	# Conditionally enable tilemap
	beq a2, 0, _no_tm
	or a0, a0, DISPLAY_MODE_TM_ENABLE

_no_tm:
	# Enable enhanced mode and write to control register
	or a0, a0, DISPLAY_MODE_ENHANCED
	sw a0, display_ctrl

	# Reset all display state. This must occur after enabling enhanced mode
	# to ensure the display is in the correct state for reset operations.
	sw zero, display_reset

	# Force a display update to clear the display
	sw zero, display_sync
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_enable_fb()
# -------------------------------------------------------------------------------------------------
# Enable the framebuffer if it isn't already enabled.
display_enable_fb:
	lw t0, display_ctrl
	or t0, t0, DISPLAY_MODE_FB_ENABLE
	sw t0, display_ctrl
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_disable_fb()
# -------------------------------------------------------------------------------------------------
# Disable the framebuffer if it's enabled.
# If the tilemap is not enabled, this has no effect (at least one has to be enabled).
display_disable_fb:
	lw t0, display_ctrl
	and t1, t0, DISPLAY_MODE_TM_ENABLE
	beq t1, 0, _return

	# Clear the framebuffer enable bit
	li t1, DISPLAY_MODE_FB_ENABLE
	not t1, t1
	and t0, t0, t1
	sw t0, display_ctrl
_return:
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_enable_tm()
# -------------------------------------------------------------------------------------------------
# Enable the tilemap if it isn't already enabled.
display_enable_tm:
	lw t0, display_ctrl
	or t0, t0, DISPLAY_MODE_TM_ENABLE
	sw t0, display_ctrl
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_disable_tm()
# -------------------------------------------------------------------------------------------------
# Disable the tilemap if it's enabled.
# If the framebuffer is not enabled, this has no effect (at least one has to be enabled).
display_disable_tm:
	lw t0, display_ctrl
	and t1, t0, DISPLAY_MODE_FB_ENABLE
	beq t1, 0, _return

	# Clear the tilemap enable bit
	li t1, DISPLAY_MODE_TM_ENABLE
	not t1, t1
	and t0, t0, t1
	sw t0, display_ctrl
_return:
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_finish_frame()
# -------------------------------------------------------------------------------------------------
# Call this at the end of each frame to display the graphics, update input, and wait the
# appropriate amount of time until the next frame.
display_finish_frame:
	sw zero, display_sync    # Trigger display update
	lw zero, display_sync    # Wait for frame completion
	jr ra

# =================================================================================================
# Input Handling
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# Macro: display_is_key_held
# -------------------------------------------------------------------------------------------------
# Sets %reg to 1 if %key is being held, 0 if not
#
# Arguments:
#   %reg - register to receive result (0 or 1)
#   %key - key constant to check (e.g., KEY_W, KEY_SPACE)
.macro display_is_key_held %reg, %key
	li %reg, %key
	sw %reg, display_key_held
	lw %reg, display_key_held
.end_macro

# -------------------------------------------------------------------------------------------------
# Macro: display_is_key_pressed
# -------------------------------------------------------------------------------------------------
# Sets %reg to 1 if %key was pressed on this frame, 0 if not
#
# Arguments:
#   %reg - register to receive result (0 or 1)
#   %key - key constant to check (e.g., KEY_W, KEY_SPACE)
.macro display_is_key_pressed %reg, %key
	li %reg, %key
	sw %reg, display_key_pressed
	lw %reg, display_key_pressed
.end_macro

# -------------------------------------------------------------------------------------------------
# Macro: display_is_key_released
# -------------------------------------------------------------------------------------------------
# Sets %reg to 1 if %key was released on this frame, 0 if not
#
# Arguments:
#   %reg - register to receive result (0 or 1)
#   %key - key constant to check (e.g., KEY_W, KEY_SPACE)
.macro display_is_key_released %reg, %key
	li %reg, %key
	sw %reg, display_key_released
	lw %reg, display_key_released
.end_macro

# =================================================================================================
# Palette Management
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# void display_load_palette(int* palette, int startIndex, int numColors)
# -------------------------------------------------------------------------------------------------
# Loads palette entries into palette RAM. Each palette entry is a word in the format
# 0xRRGGBB, e.g. 0xFF0000 is pure red, 0x00FF00 is pure green, etc.
#
# Arguments:
#   a0 - address of palette array to load (use la for this argument)
#   a1 - first color index to load it into (note: index 0 is the background color)
#   a2 - number of colors to load (should be in range [1, 256])
display_load_palette:
	# Calculate destination address
	mul a1, a1, 4
	la t0, display_palette_ram
	add a1, a1, t0

	# DO NOT FORMAT START
	# Copy each palette entry
	_loop:
		lw t0, (a0)
		sw t0, (a1)
		add a0, a0, 4
		add a1, a1, 4
		sub a2, a2, 1
	bgt a2, 0, _loop
	jr ra
	# DO NOT FORMAT END

# =================================================================================================
# Framebuffer Drawing Functions
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# void display_set_pixel(int x, int y, int color)
# -------------------------------------------------------------------------------------------------
# Sets 1 pixel to a given color. Valid colors are in the range [0, 255].
# (0, 0) is in the top LEFT, and Y increases DOWNWARDS.
#
# Arguments:
#   a0 - x coordinate
#   a1 - y coordinate
#   a2 - color index (0-255)
display_set_pixel:
	# Bounds checking
	blt a0, 0, _return
	bge a0, DISPLAY_W, _return
	blt a1, 0, _return
	bge a1, DISPLAY_H, _return

	# Calculate framebuffer address and set pixel
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	sb a2, display_fb_ram(t0)
_return:
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_draw_hline(int x, int y, int width, int color)
# -------------------------------------------------------------------------------------------------
# Draws a horizontal line on the framebuffer starting at (x, y) and going to (x + width - 1, y).
#
# Arguments:
#   a0 - x coordinate
#   a1 - y coordinate
#   a2 - width in pixels
#   a3 - color index
	.globl display_draw_hline
display_draw_hline:
	# Calculate starting address
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	la t1, display_fb_ram
	add t0, t0, t1

	# DO NOT FORMAT START
	# Draw pixels
	_loop:
		sb a3, (t0)
		inc t0
		dec a2
	bnez a2, _loop
	jr ra
	# DO NOT FORMAT END

# -------------------------------------------------------------------------------------------------
# void display_draw_vline(int x, int y, int height, int color)
# -------------------------------------------------------------------------------------------------
# Draws a vertical line on the framebuffer starting at (x, y) and going to (x, y + height - 1).
#
# Arguments:
#   a0 - x coordinate
#   a1 - y coordinate
#   a2 - height in pixels
#   a3 - color index
display_draw_vline:
	# Calculate starting address
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	la t1, display_fb_ram
	add t0, t0, t1

	# DO NOT FORMAT START
	# Draw pixels
	_loop:
		sb a3, (t0)
		add t0, t0, DISPLAY_W
		dec a2
	bnez a2, _loop
	jr ra
	# DO NOT FORMAT END

# -------------------------------------------------------------------------------------------------
# void display_draw_line(int x1, int y1, int x2, int y2, int color: v1)
# -------------------------------------------------------------------------------------------------
# Bresenham's line algorithm, integer error version.
# Not as fast as display_draw_hline/display_draw_vline; use those for axis-aligned lines.
#
# Arguments:
#   a0 - x1 coordinate
#   a1 - y1 coordinate
#   a2 - x2 coordinate
#   a3 - y2 coordinate
#   v1 - color index (non-standard argument location)
	.globl display_draw_line
display_draw_line:
	# dx:t0 = abs(x2-x1);
	sub t0, a2, a0
	abs t0, t0

	# sx:t1 = x1<x2 ? 1 : -1;
	slt t1, a0, a2    # 1 if true, 0 if not
	add t1, t1, t1    # 2 if true, 0 if not
	sub t1, t1, 1     # 1 if true, -1 if not

	# dy:t2 = -abs(y2-y1);
	sub t2, a3, a1
	abs t2, t2
	neg t2, t2

	# sy:t3 = y1<y2 ? 1 : -1;
	slt t3, a1, a3
	add t3, t3, t3
	sub t3, t3, 1

	# err:t4 = dx+dy;
	add t4, t0, t2

	# DO NOT FORMAT START
	_loop:
		# plot(x1, y1);
		sll t7, a1, DISPLAY_W_SHIFT
		add t7, t7, a0
		sb v1, display_fb_ram(t7)

		# if(x1==x2 && y1==y2) break;
		bne a0, a2, _continue
		beq a1, a3, _return

		_continue:
			add t5, t4, t4 # e2:t5 = 2*err;

			# if(e2 >= dy)
			blt t5, t2, _dx
			add t4, t4, t2 # err += dy;
			add a0, a0, t1 # x1 += sx;

			_dx: # if(e2 <= dx)
				bgt t5, t0, _loop
				add t4, t4, t0 # err += dx;
				add a1, a1, t3 # y1 += sy;
	j _loop
	# DO NOT FORMAT END

_return:
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_fill_rect(int x, int y, int width, int height, int color: v1)
# -------------------------------------------------------------------------------------------------
# Fills a rectangle of pixels (x, y) to (x + width - 1, y + height - 1) with a solid color.
#
# Arguments:
#   a0 - x coordinate
#   a1 - y coordinate
#   a2 - width in pixels
#   a3 - height in pixels
#   v1 - color index (non-standard argument location)
display_fill_rect:
	# Turn w/h into x2/y2
	add a2, a2, a0
	add a3, a3, a1

	# Turn y1/y2 into addresses
	la t0, display_fb_ram
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	move t0, a1
	# DO NOT FORMAT START
	_loop_y:
		move t1, t0
		move t2, a0

		_loop_x:
			sb v1, (t1)
			inc t1
			inc t2
		blt t2, a2, _loop_x

		add t0, t0, DISPLAY_W
	blt t0, a3, _loop_y
	jr ra
	# DO NOT FORMAT END

# -------------------------------------------------------------------------------------------------
# void display_fill_rect_fast(int x, int y, int width, int height, int color: v1)
# -------------------------------------------------------------------------------------------------
# Same as display_fill_rect, but optimized for rectangles whose X and width are multiples of 4.
# WARNING: X must be a multiple of 4 or the function will crash. Width must be a multiple of 4
# or undefined behavior will occur.
#
# Arguments:
#   a0 - x coordinate (must be multiple of 4)
#   a1 - y coordinate
#   a2 - width in pixels (must be multiple of 4)
#   a3 - height in pixels
#   v1 - color index (non-standard argument location)
display_fill_rect_fast:
	# Duplicate color across v1
	and v1, v1, 0xFF
	mul v1, v1, 0x01010101
	add a2, a2, a0                 # a2 = x2
	add a3, a3, a1                 # a3 = y2

	# t0 = display base address
	la t0, display_fb_ram

	# a1 = start address
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0

	# a3 = end address
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	# t0 = current row's start address
	move t0, a1
	# DO NOT FORMAT START
	_loop_y:
		move t1, t0 # t1 = current address
		move t2, a0 # t2 = current x

		_loop_x:
			sw v1, (t1)
			add t1, t1, 4
			add t2, t2, 4
		blt t2, a2, _loop_x

		add t0, t0, DISPLAY_W
	blt t0, a3, _loop_y
	jr ra
	# DO NOT FORMAT END

# =================================================================================================
# Tilemap Functions
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# void display_set_tile(int tx, int ty, int tileIndex, int flags)
# -------------------------------------------------------------------------------------------------
# Sets the tile at *tile* coordinates (tx, ty) to the given tile index and flags.
#
# Arguments:
#   a0 - tile x coordinate (0-31)
#   a1 - tile y coordinate (0-31)
#   a2 - tile index (0-255)
#   a3 - flags byte
display_set_tile:
	# Calculate tilemap address
	mul a1, a1, BYTES_PER_TM_ROW
	mul a0, a0, TM_ENTRY_SIZE
	add a1, a1, a0

	# Write tile entry
	sb a2, display_tm_table(a1)
	sb a3, display_tm_table + 1(a1)
	jr ra

# =================================================================================================
# Graphics Data Loading
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# void display_load_tm_gfx(int* src, int firstDestTile, int numTiles)
# -------------------------------------------------------------------------------------------------
# Loads numTiles tiles of graphics into the tilemap graphics area.
#
# Arguments:
#   a0 - address of the array from which the graphics will be copied
#   a1 - first tile in the graphics area that will be overwritten
#   a2 - number of tiles to copy (should not be negative)
display_load_tm_gfx:
	# Calculate destination address
	mul a1, a1, BYTES_PER_TILE
	la t0, display_tm_gfx
	add a1, a1, t0
	mul a2, a2, BYTES_PER_TILE
	j PRIVATE_tilecpy

# -------------------------------------------------------------------------------------------------
# void display_load_sprite_gfx(int* src, int firstDestTile, int numTiles)
# -------------------------------------------------------------------------------------------------
# Loads numTiles tiles of graphics into the sprite graphics area.
#
# Arguments:
#   a0 - address of the array from which the graphics will be copied
#   a1 - first tile in the graphics area that will be overwritten
#   a2 - number of tiles to copy (should not be negative)
display_load_sprite_gfx:
	# Calculate destination address
	mul a1, a1, BYTES_PER_TILE
	la t0, display_spr_gfx
	add a1, a1, t0
	mul a2, a2, BYTES_PER_TILE
	j PRIVATE_tilecpy

# -------------------------------------------------------------------------------------------------
# PRIVATE FUNCTION - Internal use only
# -------------------------------------------------------------------------------------------------
# Like memcpy, but (src, dest, bytes) instead of (dest, src, bytes).
# Also assumes number of bytes is a nonzero multiple of 4.
#
# Arguments:
#   a0 - source address
#   a1 - destination address
#   a2 - number of bytes
PRIVATE_tilecpy:
	# DO NOT FORMAT START
	_loop:
		lw t0, (a0)
		sw t0, (a1)
		add a0, a0, 4
		add a1, a1, 4
		sub a2, a2, 4
	bgt a2, 0, _loop
	jr ra
	# DO NOT FORMAT END

# =================================================================================================
# Text Rendering System
# =================================================================================================
# Simple text system supporting one font at a time. A font consists of a translation table that
# maps from 32-based ASCII (char - 32, since 32 is the first printable ASCII character) to tile
# indexes, and a set of graphics loaded into either tilemap or sprite graphics RAM.
#
# Fonts should call display_set_font_xlate_table when loaded.

.data
	font_xlate_table:   .word 0 # Pointer to font translation table

# Range of sprite indexes used by the sprite text functions
	text_sprites_start: .word 0
	text_sprites_end:   .word N_SPRITES

# Index of most-recently-allocated sprite (== text_sprites_end if none allocated)
# This is DECREMENTED to allocate sprites, and when it is < text_sprites_start,
# there are no sprites left.
	text_sprites_cur:   .word 0

.text
# -------------------------------------------------------------------------------------------------
# PRIVATE ERROR HANDLER
# -------------------------------------------------------------------------------------------------
PRIVATE_font_xlate_table_not_set:
	print_str "FATAL: font translation table has not been set.\n"
	li v0, 10
	syscall

# -------------------------------------------------------------------------------------------------
# void display_set_font_xlate_table(ubyte* table)
# -------------------------------------------------------------------------------------------------
# Sets the font translation table. Must be called before any other text function will work.
#
# Arguments:
#   a0 - address of translation table
display_set_font_xlate_table:
	sw a0, font_xlate_table
	jr ra

# -------------------------------------------------------------------------------------------------
# Macro: XLATE_CHAR
# -------------------------------------------------------------------------------------------------
# Translates a character using the font translation table. Non-printable characters are treated
# as spaces.
#
# Arguments:
#   %dest - destination register for tile index
#   %src - source register containing character (will be modified)
#   %xlate - register containing base address of translation table
.macro XLATE_CHAR %dest, %src, %xlate
	blt %src, 32, _nonprintable
	ble %src, 126, _printable

_nonprintable:
	li %src, ' '

_printable:
	# %dest = tile number = translation_table[ch - 32]
	sub %src, %src, 32
	add %src, %src, %xlate
	lbu %dest, (%src)
.end_macro

# -------------------------------------------------------------------------------------------------
# int display_xlate_char(int c)
# -------------------------------------------------------------------------------------------------
# Translates a character using the current font translation table. If the given character is not
# printable, treats it as a space.
#
# Arguments:
#   a0 - character to translate
# Returns:
#   v0 - tile index of that character's graphics
display_xlate_char:
	lw t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	XLATE_CHAR v0, a0, t9
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_draw_text_tm(int tx, int ty, char* str)
# -------------------------------------------------------------------------------------------------
# Draws a string of text on the tilemap with no flags set.
#
# Arguments:
#   a0 - tile x coordinate
#   a1 - tile y coordinate
#   a2 - pointer to null-terminated string
display_draw_text_tm:
	li a3, 0
	j display_draw_text_tm_flags

# -------------------------------------------------------------------------------------------------
# void display_draw_text_tm_flags(int tx, int ty, char* str, int flags)
# -------------------------------------------------------------------------------------------------
# Draws a string of text on the tilemap with the given flags on each tile.
#
# Arguments:
#   a0 - tile x coordinate
#   a1 - tile y coordinate
#   a2 - pointer to null-terminated string
#   a3 - flags byte
display_draw_text_tm_flags:
	# t9 = translation table base
	lw t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	# a1 = destination address
	mul a1, a1, BYTES_PER_TM_ROW
	mul a0, a0, TM_ENTRY_SIZE
	add a1, a1, a0
	la t0, display_tm_table
	add a1, a1, t0

	# DO NOT FORMAT START
	# Loop over each character in the string
	_loop:
		lbu t0, (a2) # t0 = ch
		beqz t0, _return # Exit loop if zero terminator

		XLATE_CHAR t0, t0, t9

		# Set tile entry
		sb t0, 0(a1)
		sb a3, 1(a1)

		add a1, a1, TM_ENTRY_SIZE # next tile entry
		inc a2 # next character in the string
	j _loop
	# DO NOT FORMAT END

_return:
	jr ra

# -------------------------------------------------------------------------------------------------
# Integer to String Conversion
# -------------------------------------------------------------------------------------------------

.data
# Temporary buffer for holding ASCII representation of integer string
# (oversized to accommodate all possible integer values)
	display_int_str_buffer:     .byte 0:49
	display_int_str_buffer_end: .byte 0

# Special-case for -2^31
	.eqv INT_MIN -2147483648
	display_int_min_str:        .asciiz "-2147483648"
	.eqv INT_MIN_STR_LEN 11
.text

# -------------------------------------------------------------------------------------------------
# PRIVATE FUNCTION - Internal use only
# (char*, int) PRIVATE_int_to_string(int value)
# -------------------------------------------------------------------------------------------------
# Interprets a0 as a signed integer and converts it to a string.
#
# Arguments:
#   a0 - integer value to convert
# Returns:
#   v0 - pointer to first character
#   v1 - number of characters produced, not including the zero terminator
# Note: v0 may point to a string constant, so the returned string should not be modified.
PRIVATE_int_to_string:
	# v0 = destination address
	la v0, display_int_str_buffer_end
	# Ensure null terminator
	sb zero, (v0)

	# if a0 == INT_MIN...
	bne a0, INT_MIN, _else
	# Special case for INT_MIN to avoid overflow issues
	la v0, display_int_min_str
	li v1, INT_MIN_STR_LEN
	j _endif

_else:
	# t9 = "is negative?"
	li t9, 0
	# if a0 is negative...
	bgez a0, _endif_neg
	# negate it
	neg a0, a0

	# remember
	li t9, 1

_endif_neg:
	# DO NOT FORMAT START
	# Produce the digits from least- to most-significant
	_loop:
		div a0, a0, 10
		mfhi t0 # extract least sig digit into t0
		mflo a0 # keep upper digits in a0

		# Convert t0 to ascii and put in buffer
		add t0, t0, '0'
		dec v0
		sb t0, (v0)
	bnez a0, _loop

	# Was it negative?
	beq t9, 0, _not_negative
	# Put a - in the buffer
	li t0, '-'
	dec v0
	sb t0, (v0)
	# DO NOT FORMAT END

_not_negative:
	# Now v0 points to first character of string.
	# Calculate number of characters
	la v1, display_int_str_buffer_end
	sub v1, v1, v0

_endif:
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_draw_int_tm(int tx, int ty, int value)
# -------------------------------------------------------------------------------------------------
# Converts value to a string (interpreted as a signed int), then draws it as text on the tilemap.
#
# Arguments:
#   a0 - tile x coordinate
#   a1 - tile y coordinate
#   a2 - integer value to draw
display_draw_int_tm:
	push ra
	push s0
	push s1
	move s0, a0
	move s1, a1

	# Convert int to string
	move a0, a2
	jal PRIVATE_int_to_string

	# Now v0 points to the string
	move a0, s0
	move a1, s1
	move a2, v0
	jal display_draw_text_tm
	pop s1
	pop s0
	pop ra
	jr ra

# =================================================================================================
# Text Sprite System
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# void display_set_text_sprites(int start, int end)
# -------------------------------------------------------------------------------------------------
# Sets sprite indexes [start, end) to be used by the text sprite system.
# end must be >= start, and both must be in the range [0, 256].
# If end == start, effectively disables text sprites.
#
# Arguments:
#   a0 - start sprite index
#   a1 - end sprite index (exclusive)
display_set_text_sprites:
	tlti a0, 0                   # trap if start index negative
	tlti a1, 0                   # trap if end index negative
	tgei a0, 257                 # trap if start index > 256
	tgei a1, 257                 # trap if end index > 256
	tlt a1, a0                   # trap if start index > end index

	sw a0, text_sprites_start
	sw a1, text_sprites_end
	sw a1, text_sprites_cur
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_clear_text_sprites()
# -------------------------------------------------------------------------------------------------
# Disables all sprites in the range set by display_set_text_sprites, and resets the current
# text sprite counter so that you can start drawing text again.
display_clear_text_sprites:
	lw t0, text_sprites_start        # t0 = loop counter
	lw t1, text_sprites_end          # t1 = loop upper bound

	# Reset the current sprite counter
	sw t1, text_sprites_cur

	# t2 = dest address
	mul t2, t0, SPRITE_ENTRY_SIZE
	la t3, display_spr_table
	add t2, t2, t3

	# DO NOT FORMAT START
	# Clear all sprites in range [start..end)
	_loop:
		bge t0, t1, _exit
		sb zero, 3(t2) # Clear flags to disable sprite
		add t2, t2, SPRITE_ENTRY_SIZE
		inc t0
	j _loop
	# DO NOT FORMAT END

_exit:
	jr ra

# -------------------------------------------------------------------------------------------------
# (int, int) display_draw_text_sprites(int px, int py, char* str)
# -------------------------------------------------------------------------------------------------
# Draws a string of text using sprites with no flags set.
#
# Arguments:
#   a0 - pixel x coordinate
#   a1 - pixel y coordinate
#   a2 - pointer to null-terminated string
# Returns:
#   v0 - start sprite index used
#   v1 - end sprite index used (exclusive)
#   If v0 == v1, either the string length was 0, or it ran out of sprites.
display_draw_text_sprites:
	li a3, 0
	j display_draw_text_sprites_flags

# -------------------------------------------------------------------------------------------------
# (int, int) display_draw_text_sprites_flags(int px, int py, char* str, int flags)
# -------------------------------------------------------------------------------------------------
# Draws a string of text using sprites with the given flags on each sprite.
# (The flags will be forced to always include BIT_ENABLE.)
#
# Arguments:
#   a0 - pixel x coordinate
#   a1 - pixel y coordinate
#   a2 - pointer to null-terminated string
#   a3 - flags byte
# Returns:
#   v0 - start sprite index used
#   v1 - end sprite index used (exclusive)
#   If v0 == v1, either the string length was 0, or it ran out of sprites.
display_draw_text_sprites_flags:
	# t6 = current sprite index
	# t7 = start of text sprites
	lw t6, text_sprites_cur
	lw t7, text_sprites_start

	# Setup return values
	move v0, t6
	move v1, t6

	# Bail out if no sprites available
	blt t6, t7, _return

	# t8 = destination address ((text_sprites_cur - 1) * SPRITE_ENTRY_SIZE)
	sub t8, t6, 1
	mul t8, t8, SPRITE_ENTRY_SIZE
	la t0, display_spr_table
	add t8, t8, t0

	# t9 = translation table base
	lw t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	# Turn on BIT_ENABLE in the flags
	or a3, a3, BIT_ENABLE

	# DO NOT FORMAT START
	# Loop over each character in the string
	_loop:
		blt t6, t7, _break
		sub t6, t6, 1 # one more sprite used

		# t0 = ch
		lbu t0, (a2)

		# Exit loop if zero terminator
		beqz t0, _break

		XLATE_CHAR t0, t0, t9

		# Set sprite entry
		sb a0, 0(t8) # X
		sb a1, 1(t8) # Y
		sb t0, 2(t8) # tile
		sb a3, 3(t8) # flags

		sub t8, t8, SPRITE_ENTRY_SIZE # next sprite entry
		add a2, a2, 1 # next character in the string
		add a0, a0, 8 # next X coordinate
	j _loop
	# DO NOT FORMAT END

_break:
	# Update the counter
	sw t6, text_sprites_cur

	# And first return value
	move v0, t6

_return:
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_draw_int_sprites(int tx, int ty, int value)
# -------------------------------------------------------------------------------------------------
# Converts value to a string (interpreted as a signed int), then draws it as sprites.
#
# Arguments:
#   a0 - pixel x coordinate
#   a1 - pixel y coordinate
#   a2 - integer value to draw
display_draw_int_sprites:
	push ra
	push s0
	push s1
	move s0, a0
	move s1, a1

	# Convert int to string
	move a0, a2
	jal PRIVATE_int_to_string

	# Now v0 points to the string
	move a0, s0
	move a1, s1
	move a2, v0
	jal display_draw_text_sprites
	pop s1
	pop s0
	pop ra
	jr ra

# =================================================================================================
# Automatic Sprite System
# =================================================================================================
# Simple sprite enqueueing system. Makes it easier to draw sprites by automatically
# keeping track of indexes and setting some common flags.

.data
# Range of sprite indexes used by the automatic sprite functions
	auto_sprites_start: .word 0
	auto_sprites_end:   .word N_SPRITES

# Index of most-recently-allocated sprite (== auto_sprites_end if none allocated)
# This is DECREMENTED to allocate sprites, and when it is < auto_sprites_start,
# there are no sprites left.
	auto_sprites_cur:   .word 0
.text

# -------------------------------------------------------------------------------------------------
# void display_set_auto_sprites(int start, int end)
# -------------------------------------------------------------------------------------------------
# Sets sprite indexes [start, end) to be used by the automatic sprite system.
# end must be >= start, and both must be in the range [0, 256].
# If end == start, effectively disables automatic sprites.
#
# Arguments:
#   a0 - start sprite index
#   a1 - end sprite index (exclusive)
display_set_auto_sprites:
	tlti a0, 0                   # trap if start index negative
	tlti a1, 0                   # trap if end index negative
	tgei a0, 257                 # trap if start index > 256
	tgei a1, 257                 # trap if end index > 256
	tlt a1, a0                   # trap if start index > end index

	sw a0, auto_sprites_start
	sw a1, auto_sprites_end
	sw a1, auto_sprites_cur
	jr ra

# -------------------------------------------------------------------------------------------------
# void display_clear_auto_sprites()
# -------------------------------------------------------------------------------------------------
# Disables all sprites in the range set by display_set_auto_sprites, and resets the current
# auto sprite counter so that you can start drawing sprites again.
display_clear_auto_sprites:
	lw t0, auto_sprites_start        # t0 = loop counter
	lw t1, auto_sprites_end          # t1 = loop upper bound

	# Reset the current sprite counter
	sw t1, auto_sprites_cur

	# t2 = dest address
	mul t2, t0, SPRITE_ENTRY_SIZE
	la t3, display_spr_table
	add t2, t2, t3

	# DO NOT FORMAT START
	# Clear all sprites in range [start..end)
	_loop:
		bge t0, t1, _exit
		sb zero, 3(t2) # Clear flags to disable sprite
		add t2, t2, SPRITE_ENTRY_SIZE
		inc t0
	j _loop
	# DO NOT FORMAT END

_exit:
	jr ra

# -------------------------------------------------------------------------------------------------
# bool display_draw_sprite(int x, int y, int tile, int flags)
# -------------------------------------------------------------------------------------------------
# Tries to allocate a sprite. If it couldn't, returns false. Otherwise, allocates a sprite and
# sets its attributes to the arguments, and returns true.
# (The flags will be forced to always include BIT_ENABLE.)
#
# Arguments:
#   a0 - x coordinate
#   a1 - y coordinate
#   a2 - tile index
#   a3 - flags byte
# Returns:
#   v0 - 1 if successful, 0 if out of sprites
display_draw_sprite:
	# t6 = current sprite index
	# t7 = start of auto sprites
	lw t0, auto_sprites_cur
	lw t1, auto_sprites_start

	# Return false if no sprites available
	li v0, 0
	blt t0, t1, _return

	# Decrement auto_sprites_cur
	dec t0
	sw t0, auto_sprites_cur

	# t8 = destination address (t0 * SPRITE_ENTRY_SIZE)
	mul t0, t0, SPRITE_ENTRY_SIZE
	la t1, display_spr_table
	add t0, t0, t1

	# Turn on BIT_ENABLE in the flags
	or a3, a3, BIT_ENABLE

	# Set sprite entry
	sb a0, 0(t0)                     # X
	sb a1, 1(t0)                     # Y
	sb a2, 2(t0)                     # tile
	sb a3, 3(t0)                     # flags

	# And return true
	li v0, 1

_return:
	jr ra
