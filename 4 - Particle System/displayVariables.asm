# Display Hardware Memory-Mapped Registers
# ------------------------
# Memory-mapped registers and memory areas for controlling the display hardware.
# These addresses are fixed by the hardware and must be placed at specific locations.
#
# IMPORTANT: This file must be included first in any program to ensure correct
# memory layout, as it resets the data segment location.

# ------------------------
# Core Display Control Registers (0xFFFF0000-0xFFFF002F)
# ------------------------
.data 0xFFFF0000
	display_ctrl:          .word 0 # Control register (0xFFFF0000)
	display_sync:          .word 0 # Frame sync trigger (0xFFFF0004)
	display_reset:         .word 0 # Display reset (0xFFFF0008)
	display_frame_counter: .word 0 # Frame counter (0xFFFF000C)

	display_fb_clear:      .word 0 # Clear framebuffer (0xFFFF0010)
	display_fb_in_front:   .word 0 # Active framebuffer selector (0xFFFF0014)
	                               #! 0 = back buffer visible, 1 = front buffer visible
	display_fb_pal_offs:   .word 0 # Palette offset (0xFFFF0018)
	display_fb_scx:        .word 0 # Framebuffer X scroll (0xFFFF001C)
	display_fb_scy:        .word 0 # Framebuffer Y scroll (0xFFFF0020)

# ------------------------
# Tilemap Control Registers (0xFFFF0030-0xFFFF003F)
# ------------------------
.data 0xFFFF0030
	display_tm_scx: .word 0 # Tilemap X scroll (0xFFFF0030)
	display_tm_scy: .word 0 # Tilemap Y scroll (0xFFFF0034)

# ------------------------
# Input Device Registers (0xFFFF0040-0xFFFF006F)
# ------------------------
.data 0xFFFF0040
	display_key_held:       .word 0 # Keyboard key held (0xFFFF0040)
	display_key_pressed:    .word 0 # Keyboard key pressed (0xFFFF0044)
	display_key_released:   .word 0 # Keyboard key released (0xFFFF0048)
	display_mouse_x:        .word 0 # Mouse X position (0xFFFF004C)
	display_mouse_y:        .word 0 # Mouse Y position (0xFFFF0050)
	display_mouse_held:     .word 0 # Mouse button held (0xFFFF0054)
	display_mouse_pressed:  .word 0 # Mouse button pressed (0xFFFF0058)
	display_mouse_released: .word 0 # Mouse button released (0xFFFF005C)
	display_mouse_wheel_x:  .word 0 # Mouse wheel X delta (0xFFFF0060)
	display_mouse_wheel_y:  .word 0 # Mouse wheel Y delta (0xFFFF0064)
	display_mouse_visible:  .word 0 # Mouse cursor visibility (0xFFFF0068)

# ------------------------
# Display Memory Areas (0xFFFF0C00-0xFFFF5BFF)
# ------------------------
.data 0xFFFF0C00
	display_palette_ram: .word 0:256 # Palette RAM (0xFFFF0C00-0xFFFF0FFF)
	display_palette_end:
	display_fb_ram:      .byte 0:16384 # Framebuffer (0xFFFF1000-0xFFFF4FFF)
	display_fb_end:
	display_tm_table:    .half 0:1024 # Tilemap table (0xFFFF5000-0xFFFF57FF)
	display_tm_end:
	display_spr_table:   .byte 0:1024 # Sprite table (0xFFFF5800-0xFFFF5BFF)
	display_spr_end:

	#! ------------------------
	#! Reserved Memory Region
	#! ------------------------
	#! WARNING: Do not write to 0xFFFF5C00-0xFFFF5FFF.

# ------------------------
# Graphics Data Storage (0xFFFF6000-0xFFFFDFFF)
# ------------------------
.data 0xFFFF6000
	display_tm_gfx:  .byte 0:16384 # Tilemap graphics (0xFFFF6000-0xFFFF9FFF)
	display_spr_gfx: .byte 0:16384 # Sprite graphics (0xFFFFA000-0xFFFFDFFF)

# ------------------------
# Reset Data Segment
# ------------------------
# Reset the default data segment location for user variables.
.data 0x10010000
.text
