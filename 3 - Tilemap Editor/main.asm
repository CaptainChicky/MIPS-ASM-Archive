# NOTE: There is an easier way to access arrays than the index calculations I do here. This is just base example.
# ------------------------
# Tilemap Editor
# ------------------------
# A simple tile-based map editor that allows users to:
# - Navigate a 16x16 grid using arrow keys
# - Place different tile types (grass, sand, brick, water) using Z/X/C/V keys
# - Load a predefined map layout from ASCII art
# - Exit the program using the Escape key
#
# The cursor position is indicated by a red frame sprite that follows user input.

	.include "displayDriver.asm"

.data
	running:       .word 1 # Program state: 1 = running, 0 = exit

	cursor_x:      .word 0 # Cursor X position (0-15)
	cursor_y:      .word 0 # Cursor Y position (0-15)

# ------------------------
# Tile Placement Configuration
# ------------------------
# Parallel arrays mapping keyboard keys to tile types.
# Press Z/X/C/V to place the corresponding tile at cursor position.
	.eqv KEYS_LEN 4
	keys_to_check: .word KEY_Z KEY_X KEY_C KEY_V
	keys_to_tiles: .word TILE_GRASS TILE_SAND TILE_BRICK TILE_WATER

# ------------------------
# Map Data
# ------------------------
# Initial map layout represented as ASCII art (16x16 characters).
# Legend:
#   ' ' (space) = grass
#   '.' (period) = sand
#   '#' (hash) = brick
#   '~' (tilde) = water
	map_data:      .ascii
		"######          "
		"#    #          "
		"#..........     "
		"#..........     "
		"#    #   ..     "
		"######   ..     "
		"         ..     "
		"         ..     "
		"         ..     "
		"         ..   .."
		"         ..  .~~"
		"         ....~~~"
		"        .~~~~~~~"
		"       .~~~~~~~~"
		"       .~~~~~~~~"
		"       .~~~~~~~~"


.text
	.global main

# ------------------------
# main
# ------------------------
# Program entry point. Initializes the display, loads graphics and map,
# then enters the main game loop which processes input and renders each frame.
main:
	jal display_init
	jal load_graphics
	jal load_map

# ------------------------
# Main Loop
# ------------------------
# Executes continuously until the user presses Escape.
# Each iteration:
#   1. Checks for keyboard input
#   2. Draws the cursor sprite at current position
#   3. Synchronizes with display timing
main_loop:
	jal check_input
	jal draw_cursor
	jal display_finish_frame

	# Check if running is still 1, if not, exit
	lw t0, running
	bne t0, zero, main_loop

# ------------------------
# Program Exit
# ------------------------
# Clean termination using syscall 10.
exit:
	li v0, 10
	syscall

# ------------------------
# load_graphics
# ------------------------
# Loads all graphics data into display memory.
# - Tilemap graphics: 4 tiles (grass, sand, brick, water)
# - Sprite graphics: 1 tile (cursor frame)
load_graphics:
	push ra

	# Load 4 tilemap tiles starting at index 0
	la a0, tilemap_gfx
	li a1, 0
	li a2, 4
	jal display_load_tm_gfx

	# Load 1 sprite tile starting at index 0
	la a0, sprite_gfx
	li a1, 0
	li a2, 1
	jal display_load_sprite_gfx

	pop ra
	jr ra


# ------------------------
# draw_cursor
# ------------------------
# Renders the cursor sprite at the current cursor position.
# The cursor is displayed as a red frame (sprite tile 0, palette 0x41).
#
# Sprite format (4 bytes):
#   Byte 0: X position (in pixels)
#   Byte 1: Y position (in pixels)
#   Byte 2: Tile number
#   Byte 3: Flags (bit 0 = enable, bits 4-7 = palette offset)
draw_cursor:
	push ra

	# Load address of sprite table (first sprite entry)
	la t2, display_spr_table

	# Convert cursor grid position (0-15) to pixel position (0-120)
	# by multiplying by tile size (8 pixels)
	lw t0, cursor_x
	mul t0, t0, 8
	sb t0, 0(t2)                # Store X position

	lw t0, cursor_y
	mul t0, t0, 8
	sb t0, 1(t2)                # Store Y position

	# Set sprite tile number to 0 (frame graphic)
	sb zero, 2(t2)

	# Set sprite flags: 0x41 = enabled (bit 0) + red palette (0x40)
	li t0, 0x41
	sb t0, 3(t2)

	pop ra
	jr ra

# ------------------------
# check_input
# ------------------------
# Polls keyboard input and responds to key presses.
# Handles:
# - Escape: Exit program
# - Arrow keys: Move cursor with wrapping at edges
# - Z/X/C/V keys: Place corresponding tile type at cursor position
#
# Uses display_key_pressed for one-time actions (Escape, arrows)
# Uses display_key_held for continuous actions (tile placement)
check_input:
	push ra
	push s0

	# ------------------------
	# Check for Escape Key (Exit)
	# ------------------------
	li t0, KEY_ESCAPE
	sw t0, display_key_pressed     # Write key to check
	lw t0, display_key_pressed     # Read result (1 = pressed, 0 = not)

	# If not pressed, skip exit logic
	beq t0, zero, _endif_Escape

	# If pressed, set running = 0 to exit main loop
	sw zero, running

_endif_Escape:

	# ------------------------
	# Check for Left Arrow Key
	# ------------------------
	li t0, KEY_LEFT
	sw t0, display_key_pressed
	lw t0, display_key_pressed

	# If not pressed, skip movement logic
	beq t0, zero, _endif_L

	# Decrement X with wraparound (0 wraps to 15)
	lw t0, cursor_x
	subi t0, t0, 1
	remu t0, t0, 16               # Modulo 16 for wraparound
	sw t0, cursor_x

_endif_L:

	# ------------------------
	# Check for Right Arrow Key
	# ------------------------
	li t0, KEY_RIGHT
	sw t0, display_key_pressed
	lw t0, display_key_pressed

	beq t0, zero, _endif_R

	# Increment X with wraparound (15 wraps to 0)
	lw t0, cursor_x
	addi t0, t0, 1
	remu t0, t0, 16
	sw t0, cursor_x

_endif_R:

	# ------------------------
	# Check for Up Arrow Key
	# ------------------------
	li t0, KEY_UP
	sw t0, display_key_pressed
	lw t0, display_key_pressed

	beq t0, zero, _endif_U

	# Decrement Y with wraparound (0 wraps to 15)
	# Note: Y increases downward in screen coordinates
	lw t0, cursor_y
	subi t0, t0, 1
	remu t0, t0, 16
	sw t0, cursor_y

_endif_U:

	# ------------------------
	# Check for Down Arrow Key
	# ------------------------
	li t0, KEY_DOWN
	sw t0, display_key_pressed
	lw t0, display_key_pressed

	beq t0, zero, _endif_D

	# Increment Y with wraparound (15 wraps to 0)
	lw t0, cursor_y
	addi t0, t0, 1
	remu t0, t0, 16
	sw t0, cursor_y

_endif_D:

	# ------------------------
	# Check Tile Placement Keys (Z, X, C, V)
	# ------------------------
	# Iterate through the parallel arrays to check each tile placement key.
	# If a key is held down, place the corresponding tile at cursor position.

	li s0, 0    # Loop counter: i = 0
_loop_tile_check:
	# Exit loop if i >= KEYS_LEN
	bge s0, KEYS_LEN, _end_tile_check

	# ------------------------
	# Load keys_to_check[i]
	# ------------------------
	la t1, keys_to_check                 # Base address of array
	mul t2, s0, 4                        # Byte offset = i * 4 (word size)
	add t1, t1, t2                       # Address of keys_to_check[i]
	lw t0, 0(t1)                         # Load key code from array

	# Check if this key is currently held
	sw t0, display_key_held              # Write key to check
	lw t0, display_key_held              # Read result (1 = held, 0 = not)

	# If key is not held, skip to next iteration
	beq t0, zero, _next_tile

	# ------------------------
	# Key is held - place corresponding tile
	# ------------------------
	# Load keys_to_tiles[i] into a2 (tile type parameter)
	la t1, keys_to_tiles                 # Base address of tile array
	mul t2, s0, 4                        # Byte offset = i * 4
	add t1, t1, t2                       # Address of keys_to_tiles[i]
	lw a2, 0(t1)                         # Load tile type

	# Load cursor position into a0 and a1
	lw a0, cursor_x
	lw a1, cursor_y

	# Call place_tile(cursor_x, cursor_y, tile_type)
	jal place_tile

_next_tile:
	addi s0, s0, 1        # i++
	j _loop_tile_check

_end_tile_check:

	pop s0
	pop ra
	jr ra

# ------------------------
# place_tile
# ------------------------
# void place_tile(int x, int y, int tile_type)
# Places a tile in the tilemap at the specified grid position.
# Arguments:
#   a0 - X coordinate (0-15)
#   a1 - Y coordinate (0-15)
#   a2 - Tile type to place (TILE_GRASS, TILE_SAND, etc.)
# Notes:
# - Tilemap is 32x32, but only 16x16 is visible/editable
# - Each tile entry is 2 bytes (halfword) in display_tm_table
# - Offset calculation: (Y * 32 + X) * 2 = Y * 64 + X * 2
place_tile:
	push ra

	# Calculate byte offset in tilemap table
	mul t0, a1, 64             # Y * 64 (32 tiles/row * 2 bytes/tile)
	mul t1, a0, 2              # X * 2 (2 bytes per tile entry)
	add t0, t0, t1             # Total offset = Y * 64 + X * 2

	# Store tile type at computed address
	la t2, display_tm_table    # Load base address of tilemap
	add t2, t2, t0             # Add offset to get target address
	sb a2, 0(t2)               # Store tile type (low byte of halfword)

	pop ra
	jr ra

# ------------------------
# load_map
# ------------------------
# Loads the initial map layout from map_data ASCII art.
# Iterates through all 16x16 positions, converts each character to
# a tile type, and places it in the tilemap.
#
# Map layout is row-major: row 0 is the first 16 chars, row 1 is next 16, etc.
load_map:
	push ra
	push s0
	push s1

	li s0, 0    # s0 = row index (0-15)
_row_loop:
	li s1, 0    # s1 = col index (0-15)

_col_loop:
	# Calculate 1D index into map_data array: row * 16 + col
	mul t0, s0, 16           # row * 16
	add t0, t0, s1           # (row * 16) + col

	# Load character from map_data[index]
	la t1, map_data          # Base address of map_data
	add t1, t1, t0           # Address of current character
	lb a0, 0(t1)             # Load ASCII character (1 byte)

	# Convert character to tile type
	jal char_to_tile_type    # Returns tile_type in a2

	# Place tile at current grid position
	move a0, s1              # x = col
	move a1, s0              # y = row
	jal place_tile

	# Advance to next column
	addi s1, s1, 1
	bne s1, 16, _col_loop    # Continue if col < 16

	# Advance to next row
	addi s0, s0, 1
	bne s0, 16, _row_loop    # Continue if row < 16

	pop s1
	pop s0
	pop ra
	jr ra

# ------------------------
# char_to_tile_type
# ------------------------
# int char_to_tile_type(char c)
# Converts an ASCII character to its corresponding tile type constant.
# Arguments:
#   a0 - ASCII character to convert
# Returns:
#   a2 - Tile type constant (TILE_GRASS, TILE_SAND, TILE_BRICK, or TILE_WATER)
# Character mapping:
#   ' ' (space) → TILE_GRASS
#   '.' (period) → TILE_SAND
#   '#' (hash) → TILE_BRICK
#   '~' (tilde) → TILE_WATER
# Notes:
# - Invalid characters cause program termination with error message
# - Returns value in a2 (not v0) for convenient chaining with place_tile
char_to_tile_type:
	push ra

	# Check for space character (grass)
	li t0, ' '
	beq a0, t0, _TILE_GRASS

	# Check for period character (sand)
	li t0, '.'
	beq a0, t0, _TILE_SAND

	# Check for hash character (brick)
	li t0, '#'
	beq a0, t0, _TILE_BRICK

	# Check for tilde character (water)
	li t0, '~'
	beq a0, t0, _TILE_WATER

	# Invalid character - print error and exit
	print_str "invalid character!\n"
	li v0, 10                           # syscall 10 = exit
	syscall

_TILE_GRASS:
	li a2, TILE_GRASS    # Return TILE_GRASS in a2
	pop ra
	jr ra

_TILE_SAND:
	li a2, TILE_SAND    # Return TILE_SAND in a2
	pop ra
	jr ra

_TILE_BRICK:
	li a2, TILE_BRICK    # Return TILE_BRICK in a2
	pop ra
	jr ra

_TILE_WATER:
	li a2, TILE_WATER    # Return TILE_WATER in a2
	pop ra
	jr ra
