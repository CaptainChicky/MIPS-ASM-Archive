# ------------------------
# Particle System
# ------------------------
# A simple particle effect system that creates a visual fountain of particles.
# Users can move the particle emitter with the mouse and spawn particles by holding
# the left mouse button.
#
# Features:
# - Mouse-controlled particle emitter position
# - Click and hold to spawn particles continuously
# - Gravity-affected particle physics with randomized velocities
# - Automatic particle lifecycle management (spawn, update, despawn)
# - Fixed-point arithmetic for smooth sub-pixel movement
#
# Technical Details:
# - Uses parallel arrays to store particle properties (active, x, y, vx, vy)
# - Fixed-point format: positions multiplied by 100 for precision (e.g., 6400 = 64.00 pixels)
# - Particles despawn when they move outside defined boundaries
#
# NOTE: This code demonstrates efficient array access patterns. Instead of loading
# the base address and adding an offset separately (la + add + load), we use
# direct indexed addressing like: lw t0, array_name(offset)

	.include "displayDriver.asm"
	.include "graphics.asm"

# ------------------------
# Particle System Constants
# ------------------------

# Maximum number of particles that can be around at one time
	.eqv MAX_PARTICLES 100

# Limits on particle positions
	.eqv PARTICLE_X_MIN -700 # -7.00 in fixed-point
	.eqv PARTICLE_X_MAX 12799 # 127.99 in fixed-point
	.eqv PARTICLE_Y_MIN -700 # -7.00 in fixed-point
	.eqv PARTICLE_Y_MAX 12799 # 127.99 in fixed-point

# Gravitational constant
	.eqv GRAVITY 7 # 0.07 in fixed-point

# Velocity randomization constants
	.eqv VEL_RANDOM_MAX 200 # 2.00 in fixed-point
	.eqv VEL_RANDOM_MAX_OVER_2 100 # 1.00 in fixed-point

# ------------------------
# Data Section
# ------------------------
.data
# ------------------------
# Emitter State
# ------------------------
# Position of the emitter (which the user has control over)
# These are in pixel coordinates, not fixed-point
	emitter_x:       .word 64
	emitter_y:       .word 10

# ------------------------
# Particle Arrays
# ------------------------
# Parallel arrays store particle properties. Each particle has an index (0 to MAX_PARTICLES-1)
# and its properties are stored at that index in each array.
#
# Example: Particle 5's properties are at:
#   - particle_active[5] - whether it's alive
#   - particle_x[5] - X position in fixed-point
#   - particle_y[5] - Y position in fixed-point
#   - particle_vx[5] - X velocity in fixed-point
#   - particle_vy[5] - Y velocity in fixed-point
#
# Array Access Pattern:
#   For byte arrays: lb/sb register, array_name(index)
#   For halfword arrays: lh/sh register, array_name(index * 2)
#
	particle_active: .byte 0:MAX_PARTICLES # Boolean (0 = inactive, 1 = active)
	particle_x:      .half 0:MAX_PARTICLES # Signed fixed-point position (multiply by 100)
	particle_y:      .half 0:MAX_PARTICLES # Signed fixed-point position (multiply by 100)
	particle_vx:     .half 0:MAX_PARTICLES # Signed fixed-point velocity
	particle_vy:     .half 0:MAX_PARTICLES # Signed fixed-point velocity

.text
	.globl main
# ------------------------
# Main Program
# ------------------------
main:
	# Initialize display
	li a0, 15            # ms per frame
	li a1, 1             # enable framebuffer
	li a2, 0             # disable tilemap
	jal display_init

	jal load_graphics

_loop:
	jal display_clear_auto_sprites

	jal check_input
	jal update_particles
	jal draw_particles
	jal draw_emitter

	jal display_finish_frame
	j _loop

	# Exit (should never get here)
	li v0, 10
	syscall

# -------------------------------------------------------------------------------------------------
# void update_particles()
# -------------------------------------------------------------------------------------------------
# Updates all active particles by applying gravity and updating positions.
# Deactivates particles that move out of bounds.
#
# Physics Model:
# - Gravity is applied each frame by adding GRAVITY to Y velocity
# - Position updates: position += velocity
# - Fixed-point arithmetic: all positions/velocities scaled by 100
update_particles:
	push ra
	push s0

	# Loop through all particles (i = 0 to MAX_PARTICLES-1)
	li s0, 0

_update_particles_loop:
	bge s0, MAX_PARTICLES, _update_particles_end

	# Check if particle is active
	# Array access: particle_active is a byte array, so we can use index directly
	lb t1, particle_active(s0)
	beq t1, zero, _update_particles_next                 # Skip inactive particles

	# Apply gravity: particle_vy[i] += GRAVITY
	# Array access: particle_vy is a halfword array, so offset = index * 2
	mul t3, s0, 2                                        # t3 = halfword offset
	lh t4, particle_vy(t3)                               # Load current Y velocity
	add t4, t4, GRAVITY                                  # Add gravity constant
	sh t4, particle_vy(t3)                               # Store updated Y velocity

	# Update X position: particle_x[i] += particle_vx[i]
	lh t4, particle_x(t3)                                # Load current X position
	lh t6, particle_vx(t3)                               # Load X velocity
	add t4, t4, t6                                       # Add velocity to position
	sh t4, particle_x(t3)                                # Store updated position

	# Update Y position: particle_y[i] += particle_vy[i]
	lh t4, particle_y(t3)                                # Load current Y position
	lh t6, particle_vy(t3)                               # Load Y velocity
	add t4, t4, t6                                       # Add velocity to position
	sh t4, particle_y(t3)                                # Store updated position

	# Bounds checking: despawn particles that leave the play area
	# Check X bounds
	lh t4, particle_x(t3)
	blt t4, PARTICLE_X_MIN, _update_particles_despawn
	bgt t4, PARTICLE_X_MAX, _update_particles_despawn

	# Check Y bounds
	lh t4, particle_y(t3)
	blt t4, PARTICLE_Y_MIN, _update_particles_despawn
	bgt t4, PARTICLE_Y_MAX, _update_particles_despawn

_update_particles_next:
	addi s0, s0, 1
	j _update_particles_loop

_update_particles_despawn:
	sb zero, particle_active(s0)    # Mark particle as inactive
	j _update_particles_next

_update_particles_end:
	pop s0
	pop ra
	jr ra

# -------------------------------------------------------------------------------------------------
# void draw_particles()
# -------------------------------------------------------------------------------------------------
# Draws all active particles as sprites on screen.
#
# Rendering Process:
# 1. Loop through all particle slots
# 2. Skip inactive particles
# 3. Convert fixed-point positions to pixel coordinates (divide by 100)
# 4. Center sprite on particle position (offset by -7 pixels)
# 5. Draw sprite using display driver
draw_particles:
	push ra
	push s0

	li s0, 0

_draw_particles_loop:
	bge s0, MAX_PARTICLES, _draw_particles_end

	# Check if particle is active
	lb t1, particle_active(s0)
	beq t1, zero, _draw_particles_next            # Skip inactive particles

	# Load particle position (in fixed-point)
	mul t3, s0, 2                                 # Halfword offset
	lh t4, particle_x(t3)                         # Load X position (fixed-point)
	lh t6, particle_y(t3)                         # Load Y position (fixed-point)

	# Convert from fixed-point to pixel coordinates
	# Fixed-point format: value * 100, so divide by 100 to get pixels
	div t4, t4, 100                               # X in pixels
	div t6, t6, 100                               # Y in pixels

	# Center the particle sprite
	# The sprite is 16x16 pixels, so offset by -7 to center it on the particle
	subi a0, t4, 7                                # Sprite X position
	subi a1, t6, 7                                # Sprite Y position

	# Set sprite tile and flags
	li a2, 161                                    # Tile index for particle graphic
	li a3, 0x88                                   # Sprite flags

	jal display_draw_sprite

_draw_particles_next:
	addi s0, s0, 1
	j _draw_particles_loop

_draw_particles_end:
	pop s0
	pop ra
	jr ra

# -------------------------------------------------------------------------------------------------
# void draw_emitter()
# -------------------------------------------------------------------------------------------------
# Draws the particle emitter sprite at the current emitter position.
draw_emitter:
	push ra

	# Load emitter position
	lw t0, emitter_x
	lw t1, emitter_y

	# Center the emitter sprite (offset by 3 pixels)
	subi a0, t0, 3
	subi a1, t1, 3

	# Set sprite tile and flags
	li a2, EMITTER_TILE
	li a3, 0x40

	jal display_draw_sprite

	pop ra
	jr ra

# -------------------------------------------------------------------------------------------------
# void check_input()
# -------------------------------------------------------------------------------------------------
# Checks mouse position and button state. Updates emitter position and spawns particles
# when the left mouse button is held.
check_input:
	push ra

	# Load mouse position
	lw t0, display_mouse_x
	lw t1, display_mouse_y

	# Check if mouse is out of bounds (-1 indicates no mouse position)
	li t2, -1
	beq t0, t2, _check_input_return

	# Update emitter position
	sw t0, emitter_x
	sw t1, emitter_y

	# Check if left mouse button is held
	lw t5, display_mouse_held
	and t5, t5, MOUSE_LBUTTON          # Isolate left button flag
	beq t5, 0, _check_input_return     # Skip if not held

	jal spawn_particle

_check_input_return:
	pop ra
	jr ra

# -------------------------------------------------------------------------------------------------
# void spawn_particle()
# -------------------------------------------------------------------------------------------------
# Spawns a new particle at the emitter position with randomized velocity.
#
# Spawning Process:
# 1. Find first inactive particle slot
# 2. Activate the particle
# 3. Set position to emitter position (converted to fixed-point)
# 4. Randomize velocity with slight upward bias
#
# Velocity Calculation:
# - VX: random(-100, 100) for horizontal spread
# - VY: random(-100, 100) - GRAVITY for initial upward motion
spawn_particle:
	push ra
	push s0

	# Find a free particle slot
	jal find_free_particle
	move s0, v0                           # s0 = particle index

	# Return if no free slots available
	li t0, -1
	beq s0, t0, _spawn_particle_return

	# Activate particle: particle_active[s0] = 1
	li t2, 1
	sb t2, particle_active(s0)

	# Set particle position to emitter position
	# Convert from pixel coordinates to fixed-point (multiply by 100)
	lw t3, emitter_x                      # Load emitter X (pixels)
	mul t3, t3, 100                       # Convert to fixed-point
	mul t5, s0, 2                         # Halfword offset for arrays
	sh t3, particle_x(t5)                 # Store particle X position

	lw t3, emitter_y                      # Load emitter Y (pixels)
	mul t3, t3, 100                       # Convert to fixed-point
	sh t3, particle_y(t5)                 # Store particle Y position

	# Randomize X velocity
	# Formula: particle_vx[i] = random(0, 200) - 100
	# This gives a range of -100 to +100 for horizontal spread
	li a0, 0                              # Random range minimum
	li a1, VEL_RANDOM_MAX                 # Random range maximum (200)
	li v0, 42                             # Syscall 42: random int in range
	syscall                               # v0 = random value in [0, 200)
	sub v0, v0, VEL_RANDOM_MAX_OVER_2     # Center around 0: v0 -= 100
	sh v0, particle_vx(t5)                # Store X velocity

	# Randomize Y velocity
	# Formula: particle_vy[i] = random(0, 200) - 100 - GRAVITY
	# The extra -GRAVITY gives an initial upward bias to the particles
	li a0, 0
	li a1, VEL_RANDOM_MAX
	li v0, 42
	syscall
	sub v0, v0, VEL_RANDOM_MAX_OVER_2     # Center around 0
	sub v0, v0, GRAVITY                   # Add upward bias
	sh v0, particle_vy(t5)                # Store Y velocity

_spawn_particle_return:
	pop s0
	pop ra
	jr ra

# -------------------------------------------------------------------------------------------------
# void load_graphics()
# -------------------------------------------------------------------------------------------------
# Loads sprite graphics and palette for particles and emitter.
load_graphics:
	push ra

	# Load emitter graphics
	la a0, emitter_gfx
	li a1, EMITTER_TILE
	li a2, N_EMITTER_TILES
	jal display_load_sprite_gfx

	# Load particle graphics
	la a0, particle_gfx
	li a1, PARTICLE_TILE
	li a2, N_PARTICLE_TILES
	jal display_load_sprite_gfx

	# Load particle palette
	la a0, particle_palette
	li a1, PARTICLE_PALETTE_OFFSET
	li a2, PARTICLE_PALETTE_SIZE
	jal display_load_palette

	pop ra
	jr ra

# -------------------------------------------------------------------------------------------------
# int find_free_particle()
# -------------------------------------------------------------------------------------------------
# Finds the first inactive particle slot in the particle arrays.
#
# Returns:
#   v0 - index of first free particle slot, or -1 if no slots available
find_free_particle:
	li v0, 0

_find_free_particle_loop:
	lb t0, particle_active(v0)
	beq t0, 0, _find_free_particle_return              # Found inactive particle

	add v0, v0, 1
	blt v0, MAX_PARTICLES, _find_free_particle_loop

	# No free particles found
	li v0, -1

_find_free_particle_return:
	jr ra
