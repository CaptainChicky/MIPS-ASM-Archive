# ========================================================================================
# Breakout Game - Main Program
# ========================================================================================
# A classic Breakout/Arkanoid-style game implementation in MIPS assembly.
# Players control a paddle to bounce a ball and destroy blocks.
#
# Game Features:
# - Mouse-controlled paddle movement with boundary clamping
# - Physics-based ball movement with collision detection
# - Block destruction with win condition checking
# - Paddle-ball interaction with angle-based bouncing
# - Visual feedback through sprite-based graphics
#
# Technical Implementation:
# - Fixed-point arithmetic for smooth sub-pixel movement (SCALE = 100)
# - Sprite-based rendering using the display driver
# - Collision detection against walls, blocks, and paddle
# - State machine for ball behavior (on paddle vs. moving)
#
# Controls:
# - Mouse movement: Control paddle position
# - Left mouse button: Launch ball from paddle
# - R key: Enable frame-by-frame stepping mode
# - F key: Advance one frame (in stepping mode)
# ========================================================================================

	.include "displayDriver.asm"
	.include "constants.asm"
	.include "graphics.asm"
	.include "levels.asm"
	.include "nesfont.asm"
	.include "sincos.asm"

# ========================================================================================
# Data Section
# ========================================================================================
.data

# ----------------------------------------------------------------------------------------
# Debug and Game State
# ----------------------------------------------------------------------------------------
	debug_framemode: .word 0 # 0 = normal play, 1 = frame-by-frame stepping mode
	game_over:       .word 0 # 0 = game in progress, 1 = all blocks destroyed

# ----------------------------------------------------------------------------------------
# Paddle State
# ----------------------------------------------------------------------------------------
# The paddle's position is stored in fixed-point coordinates (multiplied by SCALE).
# X position varies with mouse input, Y position is constant.
	paddle_x:        .word 0 # Horizontal position (fixed-point, scaled by SCALE)
	.eqv PADDLE_Y 10000 # Vertical position (constant, fixed-point)

# ----------------------------------------------------------------------------------------
# Ball State
# ----------------------------------------------------------------------------------------
# Ball position and velocity are stored in fixed-point coordinates.
# Old positions are saved for collision rollback.
	ball_y:          .word 0 # Current Y position (fixed-point)
	ball_x:          .word 0 # Current X position (fixed-point)
	ball_old_y:      .word 0 # Previous Y position (for collision recovery)
	ball_old_x:      .word 0 # Previous X position (for collision recovery)
	ball_vx:         .word 0 # X velocity (fixed-point, pixels per frame)
	ball_vy:         .word 0 # Y velocity (fixed-point, pixels per frame)

	ball_state:      .word STATE_ON_PADDLE # Current ball state (see constants.asm)

# ----------------------------------------------------------------------------------------
# Block Grid
# ----------------------------------------------------------------------------------------
# Byte array representing the game board. Each byte corresponds to one block.
# Values: BLOCK_EMPTY (0) or block type (1-N)
# Array is organized as BLOCK_ROWS rows × BLOCK_COLS columns
# Index calculation: row * BLOCK_COLS + col
	blocks:          .byte
# Default test pattern - can be modified for testing
		0 0 0 0 0 0 0 1
		0 0 0 0 0 0 0 1
		0 0 0 0 0 0 0 1
		1 1 1 1 1 1 1 1
		1 0 0 0 0 0 0 1
		1 0 0 0 0 0 0 1
		1 0 0 0 0 0 0 1
		1 1 1 1 1 1 1 1
		1 0 0 0 0 0 0 1
		1 0 0 0 0 0 0 1

# ========================================================================================
# Code Section
# ========================================================================================
.text

# ----------------------------------------------------------------------------------------
# Main Entry Point
# ----------------------------------------------------------------------------------------
# Initializes the display system, loads graphics assets, and runs the main game loop.
# The loop continues until game_over is set to 1 (all blocks destroyed).
#
# Game Loop Sequence:
#   1. Update paddle position based on mouse input
#   2. Update ball position and check collisions
#   3. Render paddle, ball, and HUD
#   4. Wait for next frame
#   5. Handle debug frame stepping if enabled
#   6. Clear sprite buffers and repeat
# ----------------------------------------------------------------------------------------
	.globl main
main:
	# Initialize display subsystem
	li a0, 15                     # ms/frame (≈60 FPS)
	li a1, 1                      # enable framebuffer
	li a2, 1                      # enable tilemap
	jal display_init

	jal load_graphics

	# Set background color (can be customized)
	# Format: 0xRRGGBB (24-bit RGB)
	li t0, 0x335577               # Blue-gray background
	sw t0, display_palette_ram

	# Optional: Load a different level
	# Uncomment and modify to load levels from levels.asm
	# Currently, uncommenting will load test_level, but changing it will load others
	#	la a0, test_level
	#	jal load_blocks

	jal draw_blocks

# ----------------------------------------------------------------------------------------
# Main Game Loop
# ----------------------------------------------------------------------------------------
_loop:
	jal update_paddle
	jal update_ball

	jal draw_paddle
	jal draw_ball
	jal draw_hud

	jal display_finish_frame

	# Debug feature: frame-by-frame stepping
	# Comment out to disable
	jal debug_do_framemode

	jal display_clear_auto_sprites
	jal display_clear_text_sprites

	lw t0, game_over
	beq t0, 0, _loop

	# Game over - show victory message
	jal show_game_over_message

	# Exit program
	li v0, 10
	syscall

# ========================================================================================
# Graphics Initialization
# ========================================================================================

# ----------------------------------------------------------------------------------------
# load_graphics
# ----------------------------------------------------------------------------------------
# Loads all graphical assets and configures sprite layers.
#
# Sprite Layer Configuration:
#   - Text sprites: IDs 0-63 (rendered on top, for HUD)
#   - Auto sprites: IDs 64-255 (rendered below, for game objects)
# ----------------------------------------------------------------------------------------
load_graphics:
	push ra
	jal load_game_graphics
	jal load_nes_font_sprite

	# Configure text sprite layer (higher priority)
	li a0, 0
	li a1, 64
	jal display_set_text_sprites

	# Configure auto sprite layer (lower priority)
	li a0, 64
	li a1, 255
	jal display_set_auto_sprites

	pop ra
	jr ra

# ========================================================================================
# Game Over Screen
# ========================================================================================

# ----------------------------------------------------------------------------------------
# show_game_over_message
# ----------------------------------------------------------------------------------------
# Displays the victory message when all blocks are destroyed.
# Customize this function to show any end-game content.
#
# Arguments: None
# Returns: None
# ----------------------------------------------------------------------------------------
show_game_over_message:
	push ra

	li a0, 2                         # X position (tile coordinates)
	li a1, 60                        # Y position (tile coordinates)
	lstr a2, "congratulations!"      # Message text
	jal display_draw_text_sprites

	jal display_finish_frame

	pop ra
	jr ra

# ========================================================================================
# Debug Features
# ========================================================================================

# ----------------------------------------------------------------------------------------
# debug_do_framemode
# ----------------------------------------------------------------------------------------
# Implements frame-by-frame stepping for debugging.
#
# Controls:
#   - R key: Enable stepping mode (pauses game)
#   - F key: Advance one frame (while in stepping mode)
#   - R key (while stepping): Return to normal play
#
# State:
#   - debug_framemode = 0: Normal continuous play
#   - debug_framemode = 1: Frame-by-frame stepping enabled
# ----------------------------------------------------------------------------------------
debug_do_framemode:
	push ra

	lw t0, debug_framemode
	beq t0, 0, _normal

_wait:
	jal display_finish_frame

	# Check for R key to exit stepping mode
	display_is_key_pressed t0, KEY_R
	beq t0, 0, _endif_r
	sw zero, debug_framemode
	j _endif

_endif_r:
	# Check for F key to advance one frame
	display_is_key_pressed t0, KEY_F
	beq t0, 0, _wait
	j _endif

_normal:
	# Check for R key to enter stepping mode
	display_is_key_pressed t0, KEY_R
	beq t0, 0, _endif
	li t0, 1
	sw t0, debug_framemode
	j _wait

_endif:
	pop ra
	jr ra

# ========================================================================================
# Block Management
# ========================================================================================

# ----------------------------------------------------------------------------------------
# load_blocks
# ----------------------------------------------------------------------------------------
# Loads a level layout from memory into the blocks array.
#
# Arguments:
#   a0 - Address of level data (byte array, N_BLOCKS bytes)
# Returns: None
#
# Level Data Format:
#   - Byte array with N_BLOCKS (BLOCK_ROWS × BLOCK_COLS) elements
#   - Each byte: 0 = empty, 1-N = block type
# ----------------------------------------------------------------------------------------
load_blocks:
	push ra

	# Copy level data to blocks array
	li t0, 0
_loop:
	lb t1, (a0)                # Load byte from level data
	sb t1, blocks(t0)          # Store to blocks array
	add a0, a0, 1              # Advance source pointer
	add t0, t0, 1              # Advance destination index
	blt t0, N_BLOCKS, _loop    # Continue for all blocks

	# Render the newly loaded level
	jal draw_blocks

	pop ra
	jr ra

# ========================================================================================
# Paddle System
# ========================================================================================

# ----------------------------------------------------------------------------------------
# update_paddle
# ----------------------------------------------------------------------------------------
# Updates paddle position based on mouse input with boundary clamping.
#
# Behavior:
#   1. Reads mouse X coordinate from display driver
#   2. Scales to fixed-point coordinate system
#   3. Clamps to valid range [PADDLE_MIN_X, PADDLE_MAX_X]
#   4. Updates paddle_x
#
# Boundary Handling:
#   - If mouse is off-screen (negative): Position unchanged
#   - If position < PADDLE_MIN_X: Clamp to minimum
#   - If position > PADDLE_MAX_X: Clamp to maximum
#
# Note: Initial paddle position is 0 (left edge). The paddle may appear partially
# off-screen until the mouse enters the display area. To center initially, change
# "paddle_x: .word 0" to "paddle_x: .word 9600" in the data section.
# ----------------------------------------------------------------------------------------
update_paddle:
	push ra

	# Read mouse X position
	lw t0, display_mouse_x             # t0 = display_mouse_x

	# Ignore update if mouse is off-screen
	bltz t0, _end_paddle_update        # If mouse X < 0, exit (mouse not on screen)

	# Convert to fixed-point coordinates
	mul t0, t0, SCALE                  # t0 = display_mouse_x * SCALE

	# Clamp to valid range using switch-case logic
	# Case 1: t0 < PADDLE_MIN_X
	blt t0, PADDLE_MIN_X, _case_min    # If position < minimum, clamp to minimum

	# Case 2: t0 > PADDLE_MAX_X
	bgt t0, PADDLE_MAX_X, _case_max    # If position > maximum, clamp to maximum

	# Default case: PADDLE_MIN_X <= t0 <= PADDLE_MAX_X (within valid range)
	j _set_paddle

_case_min:
	li t0, PADDLE_MIN_X    # Set to minimum X position
	j _set_paddle

_case_max:
	li t0, PADDLE_MAX_X    # Set to maximum X position
	j _set_paddle

_set_paddle:
	sw t0, paddle_x    # Save new paddle X position

_end_paddle_update:
	pop ra
	jr ra

# ========================================================================================
# Ball Physics System
# ========================================================================================

# ----------------------------------------------------------------------------------------
# update_ball
# ----------------------------------------------------------------------------------------
# Updates ball state based on current mode (on paddle vs. moving).
#
# State Machine:
#   STATE_ON_PADDLE:
#     - Ball follows paddle position
#     - Velocity is zero
#     - Waits for left mouse click to launch
#
#   STATE_MOVING:
#     - Updates position using velocity
#     - Checks for collisions with walls, blocks, and paddle
#     - Can transition back to STATE_ON_PADDLE if ball falls off bottom
#
# Collision Detection Order:
#   1. Save previous position (for rollback)
#   2. Update X position and check horizontal collisions
#   3. Update Y position and check vertical collisions
# ----------------------------------------------------------------------------------------
update_ball:
	push ra

	# Check current state
	lw t0, ball_state
	beq t0, STATE_ON_PADDLE, _ball_on_paddle

	# STATE_MOVING: Update position with velocity
	# Update X position
	lw t0, ball_x
	sw t0, ball_old_x                           # Save for collision rollback
	lw t1, ball_vx
	add t0, t0, t1                              # ball_x += ball_vx
	sw t0, ball_x

	jal check_horizontal_collisions

	# Update Y position
	lw t0, ball_y
	sw t0, ball_old_y                           # Save for collision rollback
	lw t1, ball_vy
	add t0, t0, t1                              # ball_y += ball_vy
	sw t0, ball_y

	jal check_vertical_collisions

	j _end_update_ball

_ball_on_paddle:
	# STATE_ON_PADDLE: Position ball on paddle
	lw t0, paddle_x
	sw t0, ball_x                   # Center ball on paddle X

	li t0, PADDLE_Y
	sub t0, t0, BALL_HALFHEIGHT     # Position above paddle
	sw t0, ball_y

	# Reset velocity
	sw zero, ball_vx
	sw zero, ball_vy

	# Check for launch input (left mouse button)
	lw t0, display_mouse_pressed
	li t1, MOUSE_LBUTTON
	and t0, t0, t1
	bnez t0, _start_ball_move

	j _end_update_ball

_start_ball_move:
	# Transition to STATE_MOVING
	li t0, STATE_MOVING
	sw t0, ball_state

	# Set initial velocity
	li t0, BALL_INITIAL_VX
	sw t0, ball_vx

	li t0, BALL_INITIAL_VY
	sw t0, ball_vy

_end_update_ball:
	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# ball_bounce_x
# ----------------------------------------------------------------------------------------
# Handles horizontal bounce by reversing X velocity and restoring position.
#
# Arguments:
#   a0 - ball_old_x (position to restore to)
#   a1 - ball_vx (current X velocity)
# Returns: None
#
# Effects:
#   - ball_x restored to old position
#   - ball_vx negated (reversed direction)
# ----------------------------------------------------------------------------------------
ball_bounce_x:
	push ra

	sw a0, ball_x     # Restore old position
	neg a1, a1        # Reverse velocity
	sw a1, ball_vx

	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# ball_get_block_horizontal
# ----------------------------------------------------------------------------------------
# Determines which block (if any) the ball is colliding with horizontally.
# Checks the leading edge of the ball in the direction of movement.
#
# Arguments: None
# Returns:
#   v0 - Block type at collision point (BLOCK_EMPTY if none)
#   v1 - Block index (or -1 if out of bounds)
#
# Logic:
#   - If ball_vx < 0 (moving left): Check left edge (ball_x - BALL_HALFWIDTH)
#   - If ball_vx > 0 (moving right): Check right edge (ball_x + BALL_HALFWIDTH - 100)
#   - Converts fixed-point to pixel coordinates and calls get_block
# ----------------------------------------------------------------------------------------
ball_get_block_horizontal:
	push ra

	lw t0, ball_vx
	blt t0, zero, _moving_left

	# Moving right: check right edge
	lw a0, ball_x
	add a0, a0, BALL_HALFWIDTH
	subi a0, a0, 100              # Small offset for better collision feel
	j _call_get_block

_moving_left:
	# Moving left: check left edge
	lw t1, ball_x
	sub a0, t1, BALL_HALFWIDTH

_call_get_block:
	# Convert to pixel coordinates and get block
	lw t2, ball_y
	div a0, a0, SCALE    # Convert X to pixels
	div a1, t2, SCALE    # Convert Y to pixels
	jal get_block

	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# check_horizontal_collisions
# ----------------------------------------------------------------------------------------
# Detects and responds to horizontal collisions (walls and blocks).
#
# Collision Cases:
#   1. Left wall: ball_x < BALL_MIN_X
#   2. Right wall: ball_x > BALL_MAX_X
#   3. Block: ball overlaps non-empty block
#
# Response:
#   - Restore ball to previous position (ball_old_x)
#   - Reverse X velocity
#   - If block collision: destroy block and redraw
# ----------------------------------------------------------------------------------------
check_horizontal_collisions:
	push ra

	# Check left wall
	lw t0, ball_x
	blt t0, BALL_MIN_X, _bounce_h

	# Check right wall
	bgt t0, BALL_MAX_X, _bounce_h

	# Check block collision
	jal ball_get_block_horizontal                       # Returns: v0=type, v1=index
	bne v0, BLOCK_EMPTY, _block_collision_detected_h

	j _end_check_horizontal

_block_collision_detected_h:
	# Destroy block and bounce
	move a0, v1          # Block index
	jal destroy_block
	j _bounce_h

_bounce_h:
	# Execute horizontal bounce
	lw a0, ball_old_x
	lw a1, ball_vx
	jal ball_bounce_x

_end_check_horizontal:
	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# ball_bounce_y
# ----------------------------------------------------------------------------------------
# Handles vertical bounce by reversing Y velocity and restoring position.
#
# Arguments:
#   a0 - ball_old_y (position to restore to)
#   a1 - ball_vy (current Y velocity)
# Returns: None
#
# Effects:
#   - ball_y restored to old position
#   - ball_vy negated (reversed direction)
# ----------------------------------------------------------------------------------------
ball_bounce_y:
	push ra

	sw a0, ball_y     # Restore old position
	neg a1, a1        # Reverse velocity
	sw a1, ball_vy

	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# ball_check_paddle
# ----------------------------------------------------------------------------------------
# Determines if the ball is currently colliding with the paddle.
#
# Arguments: None
# Returns:
#   v0 - 1 if collision detected, 0 otherwise
#
# Collision Conditions (all must be true):
#   1. Ball is moving downward (ball_vy >= 0)
#   2. Ball Y is in range: (PADDLE_Y - BALL_HALFHEIGHT) < ball_y <= PADDLE_Y
#   3. Ball X is in range: (paddle_x - PADDLE_HALFWIDTH) <= ball_x <= (paddle_x + PADDLE_HALFWIDTH)
#
# Early Exit Cases (return 0):
#   - Ball moving upward
#   - Ball below paddle
#   - Ball above paddle collision zone
#   - Ball to left of paddle
#   - Ball to right of paddle
# ----------------------------------------------------------------------------------------
ball_check_paddle:
	push ra

	# Load state variables
	lw t0, ball_vy                    # Y velocity
	lw t1, ball_y                     # Y position
	lw t2, ball_x                     # X position
	lw t3, paddle_x                   # Paddle X position
	li t7, PADDLE_Y                   # Paddle Y constant

	# Case 1: Moving upward - no collision
	bltz t0, _return_zero             # If ball_vy < 0 (moving up), return 0

	# Case 2: Below paddle - no collision
	bgt t1, PADDLE_Y, _return_zero    # If ball_y > PADDLE_Y, return 0

	# Case 3: Above collision zone - no collision
	sub t4, t7, BALL_HALFHEIGHT       # t4 = PADDLE_Y - BALL_HALFHEIGHT
	ble t1, t4, _return_zero          # If ball_y <= (PADDLE_Y - BALL_HALFHEIGHT), return 0

	# Case 4: Left of paddle - no collision
	sub t5, t3, PADDLE_HALFWIDTH      # t5 = paddle_x - PADDLE_HALFWIDTH
	blt t2, t5, _return_zero          # If ball_x < (paddle_x - PADDLE_HALFWIDTH), return 0

	# Case 5: Right of paddle - no collision
	add t6, t3, PADDLE_HALFWIDTH      # t6 = paddle_x + PADDLE_HALFWIDTH
	bgt t2, t6, _return_zero          # If ball_x > (paddle_x + PADDLE_HALFWIDTH), return 0

	# All conditions met - collision detected
	li v0, 1                          # Return 1 (collision)
	j _end_ball_check_paddle

_return_zero:
	li v0, 0    # Return 0 (no collision)

_end_ball_check_paddle:
	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# ball_get_block_vertical
# ----------------------------------------------------------------------------------------
# Determines which block (if any) the ball is colliding with vertically.
# Checks the leading edge of the ball in the direction of movement.
#
# Arguments: None
# Returns:
#   v0 - Block type at collision point (BLOCK_EMPTY if none)
#   v1 - Block index (or -1 if out of bounds)
#
# Logic:
#   - If ball_vy < 0 (moving up): Check top edge (ball_y - BALL_HALFWIDTH)
#   - If ball_vy > 0 (moving down): Check bottom edge (ball_y + BALL_HALFWIDTH - 100)
#   - Converts fixed-point to pixel coordinates and calls get_block
# ----------------------------------------------------------------------------------------
ball_get_block_vertical:
	push ra

	lw t0, ball_vy
	blt t0, zero, _moving_up

	# Moving down: check bottom edge
	lw a1, ball_y
	add a1, a1, BALL_HALFWIDTH
	subi a1, a1, 100              # Small offset for better collision feel
	j _call_get_block_v

_moving_up:
	# Moving up: check top edge
	lw t1, ball_y
	sub a1, t1, BALL_HALFWIDTH

_call_get_block_v:
	# Convert to pixel coordinates and get block
	lw t2, ball_x
	div a0, t2, SCALE    # Convert X to pixels
	div a1, a1, SCALE    # Convert Y to pixels
	jal get_block

	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# ball_bounce_paddle
# ----------------------------------------------------------------------------------------
# Handles paddle collision with angle-based bounce mechanics.
# The bounce angle depends on where the ball hits the paddle.
#
# Arguments: None
# Returns: None
#
# Bounce Angle Calculation:
#   1. Δx = |ball_x - paddle_x| (distance from paddle center)
#   2. angle = (Δx / PADDLE_HALFWIDTH) × 75 degrees
#   3. Convert angle to velocity vector using sin_cos table
#   4. Scale vector to speed magnitude of 14142 (≈141.42 in fixed-point)
#   5. Negate X component if ball hit left side of paddle
#
# Effect:
#   - Steeper angles near paddle edges
#   - Shallower angles near paddle center
#   - Ball always bounces upward (negative Y velocity)
# ----------------------------------------------------------------------------------------
ball_bounce_paddle:
	push ra

	# Restore Y position (undo movement into paddle)
	lw t0, ball_old_y
	sw t0, ball_y

	# Calculate distance from paddle center
	lw t0, ball_x
	lw t1, paddle_x
	sub t2, t0, t1                  # Δx = ball_x - paddle_x
	abs t2, t2                      # Δx = |Δx|

	# Map to angle [0, 75] degrees
	mul t2, t2, 75                  # Δx × 75
	div a0, t2, PADDLE_HALFWIDTH    # angle = (Δx × 75) / PADDLE_HALFWIDTH

	# Get sin/cos from lookup table
	jal sin_cos                     # Returns: v0=sin, v1=cos

	# Scale to velocity magnitude (14142 ≈ √2 × 10000)
	mul v0, v0, 14142               # X component
	mul v1, v1, -14142              # Y component (negative for upward)

	# Convert from table precision to fixed-point
	div v0, v0, 1000000
	div v1, v1, 1000000

	# Determine horizontal direction
	lw t0, ball_x
	lw t1, paddle_x
	blt t0, t1, _negate_x           # If ball left of center, bounce left

	j _end_of_computation

_negate_x:
	neg v0, v0    # Reverse X component

_end_of_computation:
	# Apply computed velocity
	sw v0, ball_vx
	sw v1, ball_vy

	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# check_vertical_collisions
# ----------------------------------------------------------------------------------------
# Detects and responds to vertical collisions (ceiling, floor, blocks, paddle).
#
# Coordinate System Note:
#   Y=0 is at top of screen, Y=24000 is at bottom (inverted Y-axis)
#
# Collision Cases (in priority order):
#   1. Ceiling: ball_y < BALL_MIN_Y → Bounce
#   2. Floor: ball_y > BALL_MAX_Y - adjustment → Kill ball (reset to paddle)
#   3. Paddle: ball in paddle collision zone → Angle-based bounce
#   4. Block: ball overlaps non-empty block → Destroy block and bounce
#
# Floor Adjustment:
#   - Uses (BALL_MAX_Y - BALL_HALFWIDTH × 2) to prevent visual clipping
# ----------------------------------------------------------------------------------------
check_vertical_collisions:
	push ra

	# Check ceiling collision
	lw t0, ball_y
	blt t0, BALL_MIN_Y, _bounce_v

	# Check floor collision (with visual adjustment)
	li t1, BALL_HALFWIDTH
	mul t1, t1, 2
	li t2, BALL_MAX_Y
	sub t2, t2, t1
	bgt t0, t2, _kill_ball

	# Check paddle collision
	jal ball_check_paddle                               # Returns: v0=1 if hit, 0 if miss
	bne v0, zero, _freaky_bounce

	# Check block collision
	jal ball_get_block_vertical                         # Returns: v0=type, v1=index
	bne v0, BLOCK_EMPTY, _block_collision_detected_v

	j _end_check_vertical

_block_collision_detected_v:
	# Destroy block and bounce
	move a0, v1
	jal destroy_block
	j _bounce_v

_bounce_v:
	# Execute simple vertical bounce
	lw a0, ball_old_y
	lw a1, ball_vy
	jal ball_bounce_y
	j _end_check_vertical

_kill_ball:
	# Ball fell off bottom - reset to paddle
	li t0, STATE_ON_PADDLE
	sw t0, ball_state
	j _end_check_vertical

_freaky_bounce:
	# Execute angle-based paddle bounce
	jal ball_bounce_paddle

_end_check_vertical:
	pop ra
	jr ra

# ========================================================================================
# Block System
# ========================================================================================

# ----------------------------------------------------------------------------------------
# get_block
# ----------------------------------------------------------------------------------------
# Retrieves block type and index at specified pixel coordinates.
#
# Arguments:
#   a0 - X pixel coordinate
#   a1 - Y pixel coordinate
# Returns:
#   v0 - Block type (BLOCK_EMPTY if out of bounds or empty)
#   v1 - Block index, or -1 if out of bounds
#
# Coordinate Conversion:
#   col = x / BLOCK_W
#   row = y / BLOCK_H
#   index = row × BLOCK_COLS + col
#
# Bounds Checking:
#   - Returns -1 if coordinates are negative (off-screen)
#   - Returns -1 if index >= N_BLOCKS (past end of array)
# ----------------------------------------------------------------------------------------
get_block:
	push ra

	# Check for off-screen coordinates
	beq a0, -1, _out_of_bounds
	beq a1, -1, _out_of_bounds

	# Convert pixel coordinates to grid coordinates
	div a0, a0, BLOCK_W                 # col = x / BLOCK_W
	div a1, a1, BLOCK_H                 # row = y / BLOCK_H

	# Calculate array index
	mul t0, a1, BLOCK_COLS              # row × BLOCK_COLS
	add t0, t0, a0                      # + col

	# Validate index
	bge t0, N_BLOCKS, _out_of_bounds

	# Return valid block data
	move v1, t0                         # Index
	lb v0, blocks(t0)                   # Block type
	j _end_get_block

_out_of_bounds:
	li v0, BLOCK_EMPTY
	li v1, -1

_end_get_block:
	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# destroy_block
# ----------------------------------------------------------------------------------------
# Removes a block from the game and checks for win condition.
#
# Arguments:
#   a0 - Block index
# Returns: None
#
# Actions:
#   1. Validate index (ignore if -1)
#   2. Set blocks[index] = BLOCK_EMPTY
#   3. Redraw entire block grid
#   4. Check if all blocks are destroyed (win condition)
#
# Side Effects:
#   - Updates blocks array
#   - Triggers screen redraw
#   - May set game_over = 1
# ----------------------------------------------------------------------------------------
destroy_block:
	push ra

	# Validate index
	beq a0, -1, _end_destroy_block

	# Mark block as empty
	li t1, BLOCK_EMPTY
	sb t1, blocks(a0)

	# Update display
	jal draw_blocks

	# Check win condition
	jal check_all_blocks_destroyed

_end_destroy_block:
	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# check_all_blocks_destroyed
# ----------------------------------------------------------------------------------------
# Scans entire block array to determine if all blocks are destroyed.
# Sets game_over flag if win condition is met.
#
# Arguments: None
# Returns: None
#
# Algorithm:
#   For i = 0 to N_BLOCKS-1:
#     If blocks[i] != BLOCK_EMPTY:
#       Return (game continues)
#   Set game_over = 1 (all blocks destroyed)
#
# Implementation Note:
#   This is a leaf function, so t-registers are used directly
#   without saving/restoring (no function calls made).
# ----------------------------------------------------------------------------------------
check_all_blocks_destroyed:
	push ra

	li t0, 0    # Loop counter

_loop_check_blocks:
	# Check loop condition
	bge t0, N_BLOCKS, _all_blocks_destroyed

	# Check if block is non-empty
	lb t1, blocks(t0)
	bne t1, BLOCK_EMPTY, _end_check_blocks

	# Continue to next block
	addi t0, t0, 1
	j _loop_check_blocks

_all_blocks_destroyed:
	# Set win flag
	li t2, 1
	sw t2, game_over

_end_check_blocks:
	pop ra
	jr ra

# ========================================================================================
# Rendering System
# ========================================================================================

# ----------------------------------------------------------------------------------------
# draw_blocks
# ----------------------------------------------------------------------------------------
# Renders the entire block grid to the tilemap.
# Each block is represented by two adjacent tiles (left and right halves).
#
# Grid Traversal:
#   - Outer loop: rows (0 to BLOCK_ROWS-1)
#   - Inner loop: cols (0 to BLOCK_COLS-1)
#
# Tile Positioning:
#   - Each block occupies 2 tiles horizontally
#   - Tile X position: col × 2 (left tile), col × 2 + 1 (right tile)
#   - Tile Y position: row
#
# Block Rendering:
#   - Empty blocks: Draw EMPTY_TILE for both halves
#   - Non-empty blocks: Draw BLOCK_TILE and BLOCK_TILE+1 with color flags
#
# Color Flags:
#   - Retrieved from block_palette_starts array
#   - Index: block_type - 1
# ----------------------------------------------------------------------------------------
draw_blocks:
	push ra
	push s0
	push s1

	li s0, 0    # s0 = row counter

_row_loop:
	# Check row bounds
	li t1, BLOCK_ROWS
	bge s0, t1, _end_row_loop

	li s1, 0                     # s1 = col counter

_col_loop:
	# Check column bounds
	li t3, BLOCK_COLS
	bge s1, t3, _end_col_loop          # if col >= BLOCK_COLS, end loop

	# Calculate block index: row * BLOCK_COLS + col
	mul t4, s0, t3                     # t4 = row * BLOCK_COLS
	add t4, t4, s1                     # t4 = (row * BLOCK_COLS) + col (block index)
	lb t5, blocks(t4)                  # Load block type from blocks array

	# Check if block is empty
	li t6, BLOCK_EMPTY
	beq t5, t6, _empty_block           # if block_type == BLOCK_EMPTY, draw empty tiles

	# Non-empty block: get color flags
	sub t7, t5, 1                      # t7 = block_type - 1
	lb t7, block_palette_starts(t7)    # t7 = block_palette_starts[block_type - 1] (color flags)

	# Draw left tile of block
	mul t0, s1, 2                      # t0 = col * 2 (X position for left tile)
	move a0, t0                        # x = col * 2
	move a1, s0                        # y = row
	li a2, BLOCK_TILE                  # Load BLOCK_TILE constant into a2
	move a3, t7                        # flags (color palette)
	jal display_set_tile

	# Draw right tile of block
	add t0, t0, 1                      # t0 = col * 2 + 1 (X position for right tile)
	move a0, t0                        # x = col * 2 + 1
	move a1, s0                        # y = row
	li a2, BLOCK_TILE                  # Load BLOCK_TILE constant
	add a2, a2, 1                      # a2 = BLOCK_TILE + 1 (right half sprite)
	move a3, t7                        # flags (color palette)
	jal display_set_tile

	j _next_col

_empty_block:
	# Draw left empty tile
	mul t0, s1, 2           # t0 = col * 2
	move a0, t0             # x = col * 2
	move a1, s0             # y = row
	li a2, EMPTY_TILE       # Load EMPTY_TILE constant into a2
	li a3, 0                # flags = 0 (no special flags)
	jal display_set_tile

	# Draw right empty tile
	add t0, t0, 1           # t0 = col * 2 + 1
	move a0, t0             # x = col * 2 + 1
	move a1, s0             # y = row
	li a2, EMPTY_TILE       # Load EMPTY_TILE constant into a2
	li a3, 0                # flags = 0
	jal display_set_tile

_next_col:
	add s1, s1, 1
	j _col_loop

_end_col_loop:
	add s0, s0, 1
	j _row_loop

_end_row_loop:
	pop s1
	pop s0
	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# draw_paddle
# ----------------------------------------------------------------------------------------
# Renders the paddle using three sprites (left, middle, right sections).
#
# Paddle Composition:
#   - Three 8×8 pixel sprites placed horizontally
#   - Total visual width: 24 pixels
#   - Centered on paddle_x
#
# Sprite Positioning (fixed-point to pixels):
#   - Left sprite:   (paddle_x - 1200) / SCALE
#   - Middle sprite: (paddle_x - 400) / SCALE
#   - Right sprite:  (paddle_x + 400) / SCALE
#
# All sprites share the same Y coordinate: PADDLE_Y / SCALE
#
# Sprite IDs:
#   - Left: PADDLE_TILE_LEFT
#   - Middle: PADDLE_TILE_MID
#   - Right: PADDLE_TILE_RIGHT
# ----------------------------------------------------------------------------------------
draw_paddle:
	push ra

	# Calculate Y position (shared by all sprites)
	li a1, PADDLE_Y
	div a1, a1, SCALE

	# Draw left section
	lw t0, paddle_x
	li t1, PADDLE_HALFWIDTH
	sub t1, t0, t1              # paddle_x - 1200
	div a0, t1, SCALE
	li a2, PADDLE_TILE_LEFT
	li a3, PADDLE_FLAGS
	jal display_draw_sprite

	# Draw middle section
	lw t0, paddle_x
	sub t1, t0, 400             # paddle_x - 400
	div a0, t1, SCALE
	li a2, PADDLE_TILE_MID
	jal display_draw_sprite

	# Draw right section
	lw t0, paddle_x
	addi t1, t0, 400            # paddle_x + 400
	div a0, t1, SCALE
	li a2, PADDLE_TILE_RIGHT
	jal display_draw_sprite

	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# draw_ball
# ----------------------------------------------------------------------------------------
# Renders the ball sprite at its current position.
#
# Position Calculation:
#   - Screen X: (ball_x - BALL_HALFWIDTH) / SCALE
#   - Screen Y: (ball_y - BALL_HALFHEIGHT) / SCALE
#
# Centering Logic:
#   The ball's position (ball_x, ball_y) represents its center.
#   Subtracting half-width/height converts to top-left corner for sprite rendering.
#
# Sprite Properties:
#   - Tile ID: BALL_TILE
#   - Flags: BALL_FLAGS (color/flip settings)
# ----------------------------------------------------------------------------------------
draw_ball:
	push ra

	# Calculate screen X position
	lw t0, ball_x
	sub t0, t0, BALL_HALFWIDTH
	div a0, t0, SCALE

	# Calculate screen Y position
	lw t0, ball_y
	sub t0, t0, BALL_HALFHEIGHT
	div a1, t0, SCALE

	# Draw sprite
	li a2, BALL_TILE
	li a3, BALL_FLAGS
	jal display_draw_sprite

	pop ra
	jr ra

# ----------------------------------------------------------------------------------------
# draw_hud
# ----------------------------------------------------------------------------------------
# Renders the heads-up display (currently empty).
#
# This function is called each frame and can be customized to display:
#   - Score
#   - Lives remaining
#   - Level number
#   - Timer
#   - Debug information
#
# Example implementations are commented out below for reference.
# ----------------------------------------------------------------------------------------
draw_hud:
	push ra

	# HUD rendering code goes here

	pop ra
	jr ra

	# ----------------------------------------------------------------------------------------
	# Example HUD Implementations (Commented Out)
	# ----------------------------------------------------------------------------------------

	# Example 1: Block Destruction Testing
	# Displays block type and index under mouse cursor
	# Destroys block when 'D' key is pressed
	# ----------------------------------------------------------------------------------------
	#    draw_hud:
	#    	push ra
	#    	push s1
	#
	#    	# Get block under mouse
	#    	lw a0, display_mouse_x
	#    	lw a1, display_mouse_y
	#    	jal get_block                       # Returns: v0=type, v1=index
	#
	#    	move s1, v1                         # Save index
	#
	#    	# Skip if invalid index
	#    	blt s1, zero, _end_draw_hud
	#
	#    	# Check for 'D' key press
	#    	display_is_key_pressed t0, KEY_D
	#    	beq t0, zero, _end_draw_hud
	#
	#    	# Destroy block
	#    	move a0, s1
	#    	jal destroy_block
	#
	#    _end_draw_hud:
	#    	pop s1
	#    	pop ra
	#    	jr ra

	# Example 2: Block Information Display
	# Shows block type at (1, 1) and block index at (1, 10)
	# ----------------------------------------------------------------------------------------
	#	draw_hud:
	#		push ra
	#		push s0
	#		push s1
	#
	#		# Get block under mouse
	#		lw a0, display_mouse_x
	#		lw a1, display_mouse_y
	#		jal get_block                   # Returns: v0=type, v1=index
	#
	#		move s0, v0                     # Save type
	#		move s1, v1                     # Save index
	#
	#		# Display block type
	#		li a0, 1                        # X position
	#		li a1, 1                        # Y position
	#		move a2, s0                     # Block type
	#		jal display_draw_int_sprites
	#
	#		# Display block index
	#		li a0, 1                        # X position
	#		li a1, 10                       # Y position
	#		move a2, s1                     # Block index
	#		jal display_draw_int_sprites
	#
	#		pop s1
	#		pop s0
	#		pop ra
	#		jr ra
