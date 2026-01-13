# Utility Macros
# ------------------------
# A collection of commonly-used macros that simplify assembly programming.
# Provides string handling, console I/O, and basic arithmetic operations.
# All I/O macros preserve register state to prevent side effects.
# ------------------------

# ------------------------
# MACRO: lstr
# ------------------------
# Usage:
#   lstr a0, "Hello, World!"
# Stores a string literal in the .data segment and loads its address into a register.
# This is useful for passing string addresses to functions or syscalls.
# Arguments:
#   %rd  - destination register to receive the string's address
#   %str - the string literal to store
# Notes:
# - String is stored with null terminator (.asciiz)
# - Each invocation creates a new label (lstr_message)
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
# Prints a string literal to the console using syscall 4.
# Arguments:
#   %str - the string literal to print
# Notes:
# - Preserves a0 and v0 registers automatically
# - Safe to use anywhere without affecting register state
# - Uses stack to save/restore registers
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
# MACRO: newline
# ------------------------
# Usage:
#   newline
# Prints a single newline character to the console using syscall 11.
# Notes:
# - Preserves a0 and v0 registers automatically
# - Useful for formatting output or separating lines
# - Equivalent to printing '\n'
.macro newline
	push a0
	push v0
	li a0, '\n'
	li v0, 11
	syscall
	pop v0
	pop a0
.end_macro

# ------------------------
# MACRO: println_str
# ------------------------
# Usage:
#   println_str "Hello, World!"
# Prints a string literal followed by a newline character.
# This is a convenience macro that combines print_str and newline.
# Arguments:
#   %str - the string literal to print
# Notes:
# - Preserves a0 and v0 registers automatically
# - Equivalent to print_str followed by newline
.macro println_str %str
	print_str %str
	newline
.end_macro

# ------------------------
# MACRO: inc
# ------------------------
# Usage:
#   inc t0
# Increments the value in a register by 1.
# Arguments:
#   %reg - register to increment (e.g., t0, s1, a2)
# Notes:
# - Equivalent to: addi %reg, %reg, 1
# - More readable than explicit addi for simple increments
.macro inc %reg
	addi %reg, %reg, 1
.end_macro

# ------------------------
# MACRO: dec
# ------------------------
# Usage:
#   dec t0
# Decrements the value in a register by 1.
# Arguments:
#   %reg - register to decrement (e.g., t0, s1, a2)
# Notes:
# - Equivalent to: addi %reg, %reg, -1
# - More readable than explicit addi for simple decrements
.macro dec %reg
	addi %reg, %reg, -1
.end_macro

# ------------------------
# MACRO: min
# ------------------------
# Usage:
#   min t0, t1, t2  # t0 = min(t1, t2)
# Sets the destination register to the minimum value of two source registers.
# Arguments:
#   %rd - destination register to receive the minimum value
#   %rs - first source register to compare
#   %rt - second source register to compare
# Notes:
# - Performs register-to-register comparison
# - If rs < rt, rd gets rs; otherwise rd gets rt
# - Uses internal _end label for branching
# - WARNING: Label name collision possible with multiple macros in same scope
.macro min %rd, %rs, %rt
	move %rd, %rs
	blt %rs, %rt, _end
	move %rd, %rt
_end:
.end_macro

# ------------------------
# MACRO: mini
# ------------------------
# Usage:
#   mini t0, t1, 100  # t0 = min(t1, 100)
# Sets the destination register to the minimum value of a register and an immediate.
# Arguments:
#   %rd  - destination register to receive the minimum value
#   %rs  - source register to compare
#   %imm - immediate value to compare against
# Notes:
# - Performs register-to-immediate comparison
# - If rs < imm, rd gets rs; otherwise rd gets imm
# - Uses internal _end label for branching
# - WARNING: Label name collision possible with multiple macros in same scope
.macro mini %rd, %rs, %imm
	move %rd, %rs
	blt %rs, %imm, _end
	li %rd, %imm
_end:
.end_macro

# ------------------------
# MACRO: max
# ------------------------
# Usage:
#   max t0, t1, t2  # t0 = max(t1, t2)
# Sets the destination register to the maximum value of two source registers.
# Arguments:
#   %rd - destination register to receive the maximum value
#   %rs - first source register to compare
#   %rt - second source register to compare
# Notes:
# - Performs register-to-register comparison
# - If rs > rt, rd gets rs; otherwise rd gets rt
# - Uses internal _end label for branching
# - WARNING: Label name collision possible with multiple macros in same scope
.macro max %rd, %rs, %rt
	move %rd, %rs
	bgt %rs, %rt, _end
	move %rd, %rt
_end:
.end_macro

# ------------------------
# MACRO: maxi
# ------------------------
# Usage:
#   maxi t0, t1, 100  # t0 = max(t1, 100)
# Sets the destination register to the maximum value of a register and an immediate.
# Arguments:
#   %rd  - destination register to receive the maximum value
#   %rs  - source register to compare
#   %imm - immediate value to compare against
# Notes:
# - Performs register-to-immediate comparison
# - If rs > imm, rd gets rs; otherwise rd gets imm
# - Uses internal _end label for branching
# - WARNING: Label name collision possible with multiple macros in same scope
.macro maxi %rd, %rs, %imm
	move %rd, %rs
	bgt %rs, %imm, _end
	li %rd, %imm
_end:
.end_macro
