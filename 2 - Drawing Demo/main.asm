	.include "displayDriver.asm"

# NOTE: I will no longer include "$" at the start of registers
#============================================
# PIXEL DRAWING APPLICATION
# Interactive menu for drawing pixels, lines, and rectangles
#
# Available commands:
#   [c] - Change the current drawing color
#   [p] - Draw a single pixel at specified coordinates
#   [l] - Draw a horizontal line
#   [r] - Draw a filled rectangle
#   [q] - Exit the program
#============================================

.data
# Buffer to store user's command input
	input_buffer: .space 10

# Coordinate storage for drawing operations
	x_coord:      .word 0 # Horizontal position
	y_coord:      .word 0 # Vertical position

# Current drawing color (default: white)
	color:        .word COLOR_WHITE

# Dimensions for line and rectangle
	width:        .word 0 # Horizontal size
	height:       .word 0 # Vertical size (rectangle only)

.text
	.global main

#============================================
# MAIN FUNCTION
# Initializes display and runs command loop
#============================================
main:
	jal display_init    # Initialize display driver

#--------------------------------------------
# Main command loop - prompts for user input
#--------------------------------------------
_loop:
	# Display menu header
	lstr a0, "\n========================================\n"
	li v0, 4
	syscall

	lstr a0, "    PIXEL DRAWING PROGRAM\n"
	li v0, 4
	syscall

	lstr a0, "========================================\n"
	li v0, 4
	syscall

	# Display command options
	lstr a0, "Choose a command:\n\n"
	li v0, 4
	syscall

	lstr a0, "  [c] - Change drawing color\n"
	li v0, 4
	syscall

	lstr a0, "        (Select from 16 colors)\n\n"
	li v0, 4
	syscall

	lstr a0, "  [p] - Draw a single pixel\n"
	li v0, 4
	syscall

	lstr a0, "        (Specify X and Y coordinates)\n\n"
	li v0, 4
	syscall

	lstr a0, "  [l] - Draw a horizontal line\n"
	li v0, 4
	syscall

	lstr a0, "        (Specify start position and width)\n\n"
	li v0, 4
	syscall

	lstr a0, "  [r] - Draw a filled rectangle\n"
	li v0, 4
	syscall

	lstr a0, "        (Specify corner and dimensions)\n\n"
	li v0, 4
	syscall

	lstr a0, "  [q] - Quit program\n\n"
	li v0, 4
	syscall

	lstr a0, "Enter your choice: "
	li v0, 4
	syscall

	# Read user's command
	la a0, input_buffer
	li a1, 10
	li v0, 8
	syscall

	# Get first character and dispatch to appropriate handler
	lb t0, input_buffer

	beq t0, 'c', _color
	beq t0, 'p', _pixel
	beq t0, 'l', _line
	beq t0, 'r', _rectangle
	beq t0, 'q', _quit

	# Invalid input - show error and loop again
	lstr a0, "\n*** ERROR: Invalid command! ***\n"
	li v0, 4
	syscall

	lstr a0, "Please enter c, p, l, r, or q.\n"
	li v0, 4
	syscall

	j _loop


#============================================
# COLOR SELECTION
# Allows user to change drawing color (0-15)
#============================================
_color:
	lstr a0, "\n--- COLOR SELECTION ---\n"
	li v0, 4
	syscall

	lstr a0, "Enter a color number (0-15):\n"
	li v0, 4
	syscall

	lstr a0, "  0 = Black, 15 = White\n"
	li v0, 4
	syscall

	lstr a0, "Your choice: "
	li v0, 4
	syscall

_color_input:
	# Read integer from user
	li v0, 5
	syscall

	# Validate range [0, 15]
	blt v0, 0, _color_retry
	bgt v0, 15, _color_retry

	# Convert to internal color range and store
	add v0, v0, COLOR_BLACK                           # Convert to range [64, 79]
	sw v0, color

	lstr a0, "\n>>> Color set successfully! <<<\n"
	li v0, 4
	syscall

	j _loop

_color_retry:
	lstr a0, "\nInvalid! Enter a number between 0 and 15: "
	li v0, 4
	syscall
	j _color_input


#============================================
# PIXEL DRAWING
# Draws a single pixel at (X, Y)
#============================================
_pixel:
	lstr a0, "\n--- DRAW SINGLE PIXEL ---\n"
	li v0, 4
	syscall

	# Get X coordinate
	lstr a0, "Enter X coordinate (horizontal): "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, x_coord

	# Get Y coordinate
	lstr a0, "Enter Y coordinate (vertical): "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, y_coord

	# Load coordinates and color, then draw
	lw a0, x_coord
	lw a1, y_coord
	lw a2, color

	jal display_set_pixel                           # Set the pixel
	jal display_finish_frame                        # Render to display

	lstr a0, "\n>>> Pixel drawn! <<<\n"
	li v0, 4
	syscall

	j _loop


#============================================
# LINE DRAWING
# Draws horizontal line by setting pixels in a loop
#============================================
_line:
	lstr a0, "\n--- DRAW HORIZONTAL LINE ---\n"
	li v0, 4
	syscall

	# Get starting X coordinate
	lstr a0, "Enter starting X coordinate: "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, x_coord

	# Get Y coordinate (same for entire line)
	lstr a0, "Enter Y coordinate: "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, y_coord

	# Get line width (number of pixels)
	lstr a0, "Enter line width (pixels): "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, width

	# Set up for drawing loop
	lw a0, x_coord                                 # a0 = current X (will increment)
	lw a1, y_coord                                 # a1 = Y (constant)
	lw a2, color                                   # a2 = color (constant)

	lw s0, width                                   # s0 = loop counter (pixels to draw)

_line_loop:
	beqz s0, _line_done      # Done when counter reaches zero

	jal display_set_pixel    # Draw pixel at (a0, a1)

	addi a0, a0, 1           # Move to next X position
	subi s0, s0, 1           # Decrement counter

	j _line_loop

_line_done:
	jal display_finish_frame

	lstr a0, "\n>>> Line drawn! <<<\n"
	li v0, 4
	syscall

	j _loop


#============================================
# RECTANGLE DRAWING
# Draws filled rectangle using nested loops
# Outer loop: iterates through rows (Y)
# Inner loop: iterates through columns (X)
#============================================
_rectangle:
	lstr a0, "\n--- DRAW FILLED RECTANGLE ---\n"
	li v0, 4
	syscall

	# Get top-left corner coordinates
	lstr a0, "Enter top-left X coordinate: "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, x_coord

	lstr a0, "Enter top-left Y coordinate: "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, y_coord

	# Get rectangle dimensions
	lstr a0, "Enter rectangle width (pixels): "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, width

	lstr a0, "Enter rectangle height (pixels): "
	li v0, 4
	syscall

	li v0, 5
	syscall
	sw v0, height

	# Set up for nested loops
	lw a0, x_coord                                  # a0 = current X
	lw a1, y_coord                                  # a1 = current Y
	lw a2, color                                    # a2 = color

	lw s0, width                                    # s0 = width (constant reference)
	lw s1, height                                   # s1 = rows remaining

# Outer loop - draw each row
_rectangle_outer_loop:
	beqz s1, _rectangle_done    # Done when all rows drawn

	lw a0, x_coord              # Reset X to left edge for new row
	move s3, s0                 # s3 = columns to draw in this row

# Inner loop - draw pixels across row
_rectangle_inner_loop:
	beqz s3, _rectangle_inner_done    # Done with this row

	jal display_set_pixel             # Draw pixel at (a0, a1)

	addi a0, a0, 1                    # Move to next column
	subi s3, s3, 1                    # Decrement column counter

	j _rectangle_inner_loop

_rectangle_inner_done:
	addi a1, a1, 1             # Move to next row
	subi s1, s1, 1             # Decrement row counter

	j _rectangle_outer_loop

_rectangle_done:
	jal display_finish_frame

	lstr a0, "\n>>> Rectangle drawn! <<<\n"
	li v0, 4
	syscall

	j _loop


#============================================
# QUIT
# Exit the program
#============================================
_quit:
	lstr a0, "\nExiting program. Goodbye!\n\n"
	li v0, 4
	syscall

	li v0, 10                                     # Exit syscall
	syscall
