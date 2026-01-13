# This file provides basic routines for controlling a framebuffer-based
# display. It includes initialization, per-frame updating, and pixel-level
# manipulation. Must be included first in any program to ensure correct
# memory layout.

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
# Color Palette
# ------------------------
# Classic color indexes for the default palette. Use these constants
# to select colors for pixels and other display operations.
# Note: Some colors have synonyms for convenience.
# DO NOT FORMAT START
	.eqv COLOR_BLACK       64
	.eqv COLOR_RED         65
	.eqv COLOR_ORANGE      66
	.eqv COLOR_YELLOW      67
	.eqv COLOR_GREEN       68
	.eqv COLOR_BLUE        69
	.eqv COLOR_MAGENTA     70
	.eqv COLOR_WHITE       71
	.eqv COLOR_DARK_GREY   72
	.eqv COLOR_DARK_GRAY   72
	.eqv COLOR_BRICK       73
	.eqv COLOR_BROWN       74
	.eqv COLOR_TAN         75
	.eqv COLOR_DARK_GREEN  76
	.eqv COLOR_DARK_BLUE   77
	.eqv COLOR_PURPLE      78
	.eqv COLOR_LIGHT_GREY  79
	.eqv COLOR_LIGHT_GRAY  79
# DO NOT FORMAT END

# ------------------------
# Display Registers
# ------------------------
# Memory-mapped registers for controlling the display hardware.
# Must be placed at fixed addresses for proper operation.
.data 0xFFFF0000
	display_ctrl:          .word 0 # Control register (0xFFFF0000)
	display_sync:          .word 0 # Frame sync trigger (0xFFFF0004)
	display_reset:         .word 0 # Display reset (0xFFFF0008)
	display_frame_counter: .word 0 # Frame counter (0xFFFF000C)

	display_fb_clear:      .word 0 # Clear framebuffer (0xFFFF0010)
	display_fb_in_front:   .word 0 # Active framebuffer selector (0xFFFF0014)
	display_fb_pal_offs:   .word 0 # Palette offset (0xFFFF0018)
	display_fb_scx:        .word 0 # X scroll (0xFFFF001C)
	display_fb_scy:        .word 0 # Y scroll (0xFFFF0020)

# Framebuffer memory (16 KB)
.data 0xFFFF1000
	display_fb_ram: .byte 0:16384 # 128x128 pixels, 1 byte per pixel

# Reset the default data segment for user variables
.data 0x10010000
.text

# ------------------------
# display_init
# ------------------------
# Initialize the display hardware. Must be called once at program startup.
# - Enables framebuffer and enhanced mode
# - Sets frame duration to ~15 ms
# - Resets display state
# - Forces an initial update to clear the screen
display_init:
	li t0, 0x000f0101         # 15 ms/frame, framebuffer on, enhanced mode
	sw t0, display_ctrl       # Apply control settings

	sw zero, display_reset    # Reset display
	sw zero, display_sync     # Trigger initial frame update
	jr ra

# ------------------------
# display_finish_frame
# ------------------------
# End-of-frame routine. Updates the display and waits for the next frame.
# Must be called at the end of each frame.
display_finish_frame:
	sw zero, display_sync    # Trigger frame display
	lw zero, display_sync    # Wait until frame is processed
	jr ra

# ------------------------
# display_set_pixel
# ------------------------
# void display_set_pixel(int x, int y, int color)
# Sets a single pixel in the framebuffer.
# Arguments:
#   a0 - x coordinate (0-127, left to right)
#   a1 - y coordinate (0-127, top to bottom)
#   a2 - color index (0-255)
# Notes:
# - Out-of-bounds coordinates are ignored
# - The framebuffer is linear: pixel offset = y*128 + x
display_set_pixel:
	blt a0, 0, _return
	bge a0, 128, _return
	blt a1, 0, _return
	bge a1, 128, _return

	mul t0, a1, 128              # row offset
	add t0, t0, a0               # total pixel offset
	sb a2, display_fb_ram(t0)    # write pixel
_return:
	jr ra
