# This file provides comprehensive routines for controlling a tilemap and sprite-based
# display system. It includes initialization, graphics loading, and per-frame updating.
# Must be included first in any program to ensure correct memory layout of display registers.

# ------------------------
# MACRO: lstr
# ------------------------
# Usage:
#   lstr a0, "Hello, World!"
# Stores a string in the .data segment and loads its address into a register.
# Arguments:
#   %rd  - destination register to receive the string's address
#   %str - the string literal to store
.macro lstr %rd, %str
.data
	lstr_message: .asciiz %str
.text
	la %rd, lstr_message
.end_macro

# ------------------------
# MACRO: print_str
# ------------------------
# Usage:
#   print_str "Hello, World!"
# Prints a string to the console using syscall 4.
# Arguments:
#   %str - the string literal to print
# Notes:
# - Preserves a0 and v0 registers automatically
# - Safe to use anywhere without affecting register state
.macro print_str %str
	push a0
	push v0
	lstr a0, %str
	li v0, 4
	syscall
	pop v0
	pop a0
.end_macro

# ------------------------
# Color Palette
# ------------------------
# Classic color indexes for the default palette. Use these constants
# to select colors for pixels, tiles, and sprites.
# Note: Some colors have synonyms (GREY/GRAY) for convenience.
# DO NOT FORMAT START
	.eqv COLOR_BLACK       0x40
	.eqv COLOR_RED         0x41
	.eqv COLOR_ORANGE      0x42
	.eqv COLOR_YELLOW      0x43
	.eqv COLOR_GREEN       0x44
	.eqv COLOR_BLUE        0x45
	.eqv COLOR_MAGENTA     0x46
	.eqv COLOR_WHITE       0x47
	.eqv COLOR_DARK_GREY   0x48
	.eqv COLOR_DARK_GRAY   0x48
	.eqv COLOR_BRICK       0x49
	.eqv COLOR_BROWN       0x4A
	.eqv COLOR_TAN         0x4B
	.eqv COLOR_DARK_GREEN  0x4C
	.eqv COLOR_DARK_BLUE   0x4D
	.eqv COLOR_PURPLE      0x4E
	.eqv COLOR_LIGHT_GREY  0x4F
	.eqv COLOR_LIGHT_GRAY  0x4F
# DO NOT FORMAT END

# ------------------------
# Keyboard Input Constants
# ------------------------
# Key codes for common keyboard inputs. Use these to check
# key_held, key_pressed, and key_released registers.
# DO NOT FORMAT START
	.eqv KEY_ESCAPE 27
	.eqv KEY_LEFT   37
	.eqv KEY_UP     38
	.eqv KEY_RIGHT  39
	.eqv KEY_DOWN   40
	.eqv KEY_Z      90
	.eqv KEY_X      88
	.eqv KEY_C      67
	.eqv KEY_V      86
# DO NOT FORMAT END

# ------------------------
# Tile Type Constants
# ------------------------
# Predefined tile types for the tilemap system.
# Each tile is 8x8 pixels with its own graphics.
# DO NOT FORMAT START
	.eqv TILE_GRASS 0
	.eqv TILE_SAND  1
	.eqv TILE_BRICK 2
	.eqv TILE_WATER 3

	.eqv TILE_W 8  # Tile width in pixels
	.eqv TILE_H 8  # Tile height in pixels
# DO NOT FORMAT END

# ------------------------
# Display Registers
# ------------------------
# Memory-mapped registers for controlling the display hardware.
# Must be placed at fixed addresses for proper operation.
# Note: This resets the data segment location, so this file must
# be included first in any program that uses it.

.data 0xFFFF0000
	display_ctrl:          .word 0 # Control register (0xFFFF0000)
	display_sync:          .word 0 # Frame sync trigger (0xFFFF0004)
	display_reset:         .word 0 # Display reset (0xFFFF0008)
	display_frame_counter: .word 0 # Frame counter (0xFFFF000C)

	display_fb_clear:      .word 0 # Clear framebuffer (0xFFFF0010)
	display_fb_in_front:   .word 0 # Active framebuffer selector (0xFFFF0014)
	display_fb_pal_offs:   .word 0 # Palette offset (0xFFFF0018)
	display_fb_scx:        .word 0 # Framebuffer X scroll (0xFFFF001C)
	display_fb_scy:        .word 0 # Framebuffer Y scroll (0xFFFF0020)

.data 0xFFFF0030
	display_tm_scx: .word 0 # Tilemap X scroll (0xFFFF0030)
	display_tm_scy: .word 0 # Tilemap Y scroll (0xFFFF0034)

.data 0xFFFF0040
	display_key_held:     .word 0 # Keys currently held down (0xFFFF0040)
	display_key_pressed:  .word 0 # Keys pressed this frame (0xFFFF0044)
	display_key_released: .word 0 # Keys released this frame (0xFFFF0048)

# ------------------------
# Display Memory Areas
# ------------------------
# Various memory regions for display data.
# - Palette RAM: 256 colors, 4 bytes each (RGBA format)
# - Framebuffer RAM: 128x128 pixels, 1 byte per pixel
# - Tilemap table: 32x32 tiles, 2 bytes per tile entry
# - Sprite table: Up to 128 sprites, 8 bytes per sprite
.data 0xFFFF0C00
	display_palette_ram: .word 0:256 # Palette RAM (0xFFFF0C00-0xFFFF0FFF)
	display_palette_end:
	display_fb_ram:      .byte 0:16384 # Framebuffer (0xFFFF1000-0xFFFF4FFF)
	display_fb_end:
	display_tm_table:    .half 0:1024 # Tilemap table (0xFFFF5000-0xFFFF57FF)
	display_tm_end:
	display_spr_table:   .byte 0:1024 # Sprite table (0xFFFF5800-0xFFFF5BFF)
	display_spr_end:

# ------------------------
# Graphics Data Storage
# ------------------------
# Memory areas for storing tile and sprite graphics.
# - Tilemap graphics: 256 tiles, 64 bytes each (8x8 pixels)
# - Sprite graphics: 256 tiles, 64 bytes each (8x8 pixels)
.data 0xFFFF6000
	display_tm_gfx:  .byte 0:16384 # Tilemap graphics (0xFFFF6000-0xFFFF9FFF)
	display_spr_gfx: .byte 0:16384 # Sprite graphics (0xFFFFA000-0xFFFFDFFF)

# Reset the default data segment for user variables.
# This ensures user-defined data starts at the standard location.
.data 0x10010000

# ------------------------
# Graphics Data: Tilemap
# ------------------------
# Predefined 8x8 pixel graphics for tilemap tiles.
# Each byte represents one pixel using a palette color index.
# Four tile types are defined: grass, sand, brick, and water.
	#! graphics data for the tilemap (kinds of ground tiles)
	tilemap_gfx: .byte
		#! grass - green with darker green accents
		0x44 0x44 0x44 0x44 0x44 0x44 0x44 0x44
		0x44 0x4C 0x44 0x44 0x44 0x44 0x4C 0x44
		0x44 0x44 0x44 0x4C 0x44 0x44 0x44 0x44
		0x44 0x44 0x44 0x44 0x44 0x44 0x44 0x44
		0x44 0x44 0x44 0x44 0x44 0x44 0x4C 0x44
		0x44 0x4C 0x44 0x44 0x44 0x44 0x44 0x44
		0x44 0x44 0x44 0x44 0x44 0x4C 0x44 0x44
		0x44 0x44 0x44 0x4C 0x44 0x44 0x44 0x44

		#! sand - tan with darker brown accents
		0x4B 0x4B 0x4B 0x4B 0x4B 0x4B 0x4B 0x4B
		0x4B 0x4A 0x4B 0x4B 0x4B 0x4B 0x4A 0x4B
		0x4B 0x4B 0x4B 0x4A 0x4B 0x4B 0x4B 0x4B
		0x4B 0x4B 0x4B 0x4B 0x4B 0x4B 0x4B 0x4B
		0x4B 0x4B 0x4B 0x4B 0x4B 0x4B 0x4A 0x4B
		0x4B 0x4A 0x4B 0x4B 0x4B 0x4B 0x4B 0x4B
		0x4B 0x4B 0x4B 0x4B 0x4B 0x4A 0x4B 0x4B
		0x4B 0x4B 0x4B 0x4A 0x4B 0x4B 0x4B 0x4B

		#! brick - brick red with light gray mortar lines
		0x49 0x49 0x4F 0x49 0x49 0x49 0x49 0x49
		0x49 0x49 0x4F 0x49 0x49 0x49 0x49 0x49
		0x49 0x49 0x4F 0x49 0x49 0x49 0x49 0x49
		0x4F 0x4F 0x4F 0x4F 0x4F 0x4F 0x4F 0x4F
		0x49 0x49 0x49 0x49 0x49 0x4F 0x49 0x49
		0x49 0x49 0x49 0x49 0x49 0x4F 0x49 0x49
		0x49 0x49 0x49 0x49 0x49 0x4F 0x49 0x49
		0x4F 0x4F 0x4F 0x4F 0x4F 0x4F 0x4F 0x4F

		#! water - blue with darker blue wave pattern
		0x45 0x45 0x45 0x45 0x45 0x45 0x45 0x45
		0x45 0x45 0x45 0x45 0x45 0x45 0x45 0x45
		0x45 0x4D 0x45 0x45 0x4D 0x45 0x45 0x4D
		0x45 0x45 0x4D 0x4D 0x45 0x4D 0x4D 0x45
		0x45 0x45 0x45 0x45 0x45 0x45 0x45 0x45
		0x45 0x45 0x45 0x45 0x45 0x45 0x45 0x45
		0x45 0x45 0x45 0x45 0x45 0x45 0x45 0x45
		0x45 0x45 0x45 0x45 0x45 0x45 0x45 0x45

# ------------------------
# Graphics Data: Sprites
# ------------------------
# Predefined 8x8 pixel graphics for sprites.
# Pixel value 0 is treated as transparent.
	#! graphics data for the sprites (well, the one sprite)
	sprite_gfx:  .byte
		#! tile "frame" - decorative border frame
		0x01 0x01 0x01 0x00 0x00 0x01 0x01 0x01
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
		0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x01
		0x01 0x01 0x01 0x00 0x00 0x01 0x01 0x01
.text

# ------------------------
# display_init
# ------------------------
# Initialize the display hardware. Must be called once at program startup.
# - Enables framebuffer, tilemap, and enhanced mode
# - Sets frame duration to ~15 ms
# - Resets all display state
# - Forces an initial update to clear the screen
display_init:
	li t0, 0x000f0103         # 15 ms/frame, framebuffer on, tilemap on, enhanced mode
	sw t0, display_ctrl       # Apply control settings
	sw zero, display_reset    # Reset all display state
	sw zero, display_sync     # Trigger initial frame update
	jr ra

# ------------------------
# display_finish_frame
# ------------------------
# End-of-frame routine. Updates the display and waits for the next frame.
# Must be called at the end of each frame to synchronize with display timing.
# - Triggers the display to render the current state
# - Blocks until the frame is complete and timing is satisfied
display_finish_frame:
	sw zero, display_sync    # Trigger frame display
	lw zero, display_sync    # Wait until frame is processed
	jr ra

# ------------------------
# display_load_tm_gfx
# ------------------------
# void display_load_tm_gfx(int* src, int firstDestTile, int numTiles)
# Loads tile graphics into the tilemap graphics area.
# Arguments:
#   a0 - source address of tile graphics data
#   a1 - first destination tile index to overwrite (0-255)
#   a2 - number of tiles to copy (should be > 0)
# Notes:
# - Each tile is 64 bytes (8x8 pixels)
# - Graphics are copied to display_tm_gfx memory region
# - Used for background/terrain tiles
display_load_tm_gfx:
	mul a1, a1, 64           # Convert tile index to byte offset
	la t0, display_tm_gfx    # Load base address of tilemap graphics
	add a1, a1, t0           # Calculate destination address
	mul a2, a2, 64           # Convert tile count to byte count
	j PRIVATE_tilecpy

# ------------------------
# display_load_sprite_gfx
# ------------------------
# void display_load_sprite_gfx(int* src, int firstDestTile, int numTiles)
# Loads tile graphics into the sprite graphics area.
# Arguments:
#   a0 - source address of tile graphics data
#   a1 - first destination tile index to overwrite (0-255)
#   a2 - number of tiles to copy (should be > 0)
# Notes:
# - Each tile is 64 bytes (8x8 pixels)
# - Graphics are copied to display_spr_gfx memory region
# - Used for movable objects/characters
# - Pixel value 0 is treated as transparent
display_load_sprite_gfx:
	mul a1, a1, 64            # Convert tile index to byte offset
	la t0, display_spr_gfx    # Load base address of sprite graphics
	add a1, a1, t0            # Calculate destination address
	mul a2, a2, 64            # Convert tile count to byte count
	j PRIVATE_tilecpy

# ------------------------
# PRIVATE_tilecpy
# ------------------------
# PRIVATE FUNCTION - DO NOT CALL DIRECTLY!
# Optimized memory copy routine for tile data.
# Similar to memcpy but with (src, dest, bytes) parameter order.
# Arguments:
#   a0 - source address
#   a1 - destination address
#   a2 - number of bytes to copy (must be nonzero multiple of 4)
# Notes:
# - Copies 4 bytes per iteration for efficiency
# - Assumes byte count is valid (no bounds checking)
PRIVATE_tilecpy:
	# DO NOT FORMAT START
	_loop:
		lw t0, (a0)           # Read 4 bytes from source
		sw t0, (a1)           # Write 4 bytes to destination
		add a0, a0, 4         # Advance source pointer
		add a1, a1, 4         # Advance destination pointer
		sub a2, a2, 4         # Decrement byte counter
	bgt a2, 0, _loop          # Continue if bytes remain
	jr ra
	# DO NOT FORMAT END
