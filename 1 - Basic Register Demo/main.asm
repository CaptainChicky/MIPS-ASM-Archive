.data
# String constants
	recommend_msg:   .asciiz "I recommend going through instructions one at a time manually during running to see what's going on.\n\n"
	hello_message:   .asciiz "Hello, world!\n"
	greeting_prefix: .asciiz "Hello, "
	prompt_num1:     .asciiz "Enter first number: "
	prompt_num2:     .asciiz "Enter second number: "
	result_msg:      .asciiz "The sum is: "
	prompt_name:     .asciiz "\nWhat's your name? "
	input_buffer:    .space 50

.text
	.globl main

#=========================
# MAIN PROGRAM
#=========================
main:
	# Print recommendation message
	la $a0, recommend_msg      # Load message address
	li $v0, 4                  # Syscall 4: print string
	syscall

	#=========================
	# Demo 1: Register Operations
	#=========================
	# Initialize some registers with values
	li $t0, 1                  # $t0 = 1
	li $t1, 2                  # $t1 = 2
	li $t2, 3                  # $t2 = 3

	# Move values between registers
	move $a0, $t0              # $a0 = $t0 (1)
	move $v0, $t1              # $v0 = $t1 (2)
	move $t2, zero             # $t2 = 0 (reset)

	#=========================
	# Demo 2: Print Integers
	#=========================
	# Print first number (123)
	li $a0, 123                # Load value to print
	li $v0, 1                  # Syscall 1: print integer
	syscall

	# Print newline
	li $a0, '\n'               # ASCII newline character
	li $v0, 11                 # Syscall 11: print character
	syscall

	# Print second number (456)
	li $a0, 456                # Load value to print
	li $v0, 1                  # Syscall 1: print integer
	syscall

	# Print newline
	li $a0, '\n'
	li $v0, 11
	syscall

	#=========================
	# Demo 3: Read & Add Two Numbers
	#=========================
	# Prompt for first number
	la $a0, prompt_num1        # Load prompt address
	li $v0, 4                  # Syscall 4: print string
	syscall

	# Read first integer
	li $v0, 5                  # Syscall 5: read integer
	syscall
	move $s0, $v0              # Store in $s0 (safe register)

	# Prompt for second number
	la $a0, prompt_num2        # Load prompt address
	li $v0, 4                  # Syscall 4: print string
	syscall

	# Read second integer
	li $v0, 5                  # Syscall 5: read integer
	syscall
	move $s1, $v0              # Store in $s1 (safe register)

	# Display result message
	la $a0, result_msg         # Load result message
	li $v0, 4                  # Syscall 4: print string
	syscall

	# Calculate and print sum
	add $a0, $s0, $s1          # $a0 = $s0+$s1
	li $v0, 1                  # Syscall 1: print integer
	syscall

	# Print newline
	li $a0, '\n'
	li $v0, 11
	syscall

	#=========================
	# Demo 4: Print "Hello, world!"
	#=========================
	la $a0, hello_message      # Load hello message address
	li $v0, 4                  # Syscall 4: print string
	syscall

	#=========================
	# Demo 5: Read & Greet User
	#=========================
	# Prompt for name
	la $a0, prompt_name        # Load name prompt
	li $v0, 4                  # Syscall 4: print string
	syscall

	# Read user's name
	la $a0, input_buffer       # Buffer address
	li a1, 50                  # Maximum length
	li $v0, 8                  # Syscall 8: read string
	syscall

	# Print greeting prefix
	la $a0, greeting_prefix    # Load "Hello, "
	li $v0, 4                  # Syscall 4: print string
	syscall

	# Print user's name
	la $a0, input_buffer       # Load user input
	li $v0, 4                  # Syscall 4: print string
	syscall

	#=========================
	# Exit Program
	#=========================
	li $v0, 10                 # Syscall 10: exit
	syscall
