# Breakout Game Constants
# ------------------------
# Constants for block types, game dimensions, physics, and ball states

# ------------------------
# Block Types
# ------------------------
    # DO NOT FORMAT START
    .eqv BLOCK_EMPTY  0 # Empty block (no block present)
    .eqv BLOCK_RED    1 # Red block
    .eqv BLOCK_YELLOW 2 # Yellow block
    .eqv BLOCK_GREEN  3 # Green block
    .eqv BLOCK_BLUE   4 # Blue block
    .eqv BLOCK_PURPLE 5 # Purple block
    .eqv BLOCK_PINK   6 # Pink block
    # DO NOT FORMAT END

# ------------------------
# Block Constants
# ------------------------
    # DO NOT FORMAT START
    .eqv BLOCK_COLS 8  # Number of block columns
    .eqv BLOCK_ROWS 10 # Number of block rows
    .eqv N_BLOCKS   80 # Total number of blocks
    .eqv BLOCK_W    16 # Block width in pixels
    .eqv BLOCK_H    8  # Block height in pixels
    # DO NOT FORMAT END

# ------------------------
# Fixed-Point Scale
# ------------------------
	.eqv SCALE 100 # Fixed-point scaling factor (x100)

# ------------------------
# Paddle Boundaries
# ------------------------
	.eqv PADDLE_MIN_X 1200 # Minimum paddle x position (x100)
	.eqv PADDLE_MAX_X 11600 # Maximum paddle x position (x100)

# ------------------------
# Paddle Dimensions
# ------------------------
	.eqv PADDLE_HALFWIDTH 1200 # Half-width of paddle (x100)

# ------------------------
# Ball States
# ------------------------
    # DO NOT FORMAT START
    .eqv STATE_ON_PADDLE 0 # Ball is resting on paddle
    .eqv STATE_MOVING    1 # Ball is in motion
    # DO NOT FORMAT END

# ------------------------
# Ball Launch Velocity
# ------------------------
    # DO NOT FORMAT START
    .eqv BALL_INITIAL_VX 100 # Initial ball x velocity (x100)
    .eqv BALL_INITIAL_VY -100 # Initial ball y velocity (x100)
    # DO NOT FORMAT END

# ------------------------
# Ball Boundaries
# ------------------------
	.eqv BALL_MIN_X 300 # Minimum ball x position (x100)
	.eqv BALL_MAX_X 12500 # Maximum ball x position (x100)
	.eqv BALL_MIN_Y 300 # Minimum ball y position (x100)
	.eqv BALL_MAX_Y 13100 # Maximum ball y position (x100)

# ------------------------
# Ball Dimensions
# ------------------------
    # DO NOT FORMAT START
    .eqv BALL_HALFWIDTH  300 # Half-width of ball (x100)
    .eqv BALL_HALFHEIGHT 300 # Half-height of ball (x100)
    # DO NOT FORMAT END
