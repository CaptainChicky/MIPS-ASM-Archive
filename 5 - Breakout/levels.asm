.data
# ------------------------
# Test Level
# ------------------------
# 10 rows x 8 columns
# Contains scattered blocks of different colors
	test_level:
		.byte
		0 1 0 0 0 0 0 0
		0 0 0 0 0 0 6 0
		0 0 0 0 0 0 0 0
		1 0 4 0 0 5 0 0
		2 0 0 0 0 0 0 0
		3 0 0 0 0 0 0 0
		4 0 0 3 0 0 0 0
		5 0 0 0 0 0 0 0
		6 0 0 0 0 0 0 0
		0 0 0 1 2 0 0 0

# ------------------------
# Heart Level
# ------------------------
# 10 rows x 8 columns
# Forms a heart shape using blocks
	heart_level:
		.byte
		0 0 0 0 0 0 0 0
		0 0 0 0 0 0 0 0
		0 1 1 0 0 1 1 0
		1 6 6 1 1 6 6 1
		1 6 6 6 6 6 6 1
		1 6 6 6 6 6 6 1
		1 6 6 6 6 6 6 1
		0 1 6 6 6 6 1 0
		0 0 1 6 6 1 0 0
		0 0 0 1 1 0 0 0

# ------------------------
# Spiral Level
# ------------------------
# 10 rows x 8 columns
# Forms a spiral pattern using blocks
	spiral_level:
		.byte
		2 2 2 2 2 2 2 1
		3 0 0 0 0 0 0 1
		3 0 6 6 6 5 0 1
		3 0 1 0 0 5 0 1
		3 0 1 0 0 5 0 1
		3 0 1 3 0 5 0 1
		3 0 1 2 0 5 0 1
		3 0 0 0 0 5 0 1
		3 4 4 4 4 4 0 1
		0 0 0 0 0 0 0 1

# ------------------------
# Checkerboard Level
# ------------------------
# 10 rows x 8 columns
# Forms a checkerboard pattern using blocks
	checkerboard_level:
		.byte
		1 0 1 0 1 0 1 0
		0 2 0 2 0 2 0 2
		3 0 3 0 3 0 3 0
		0 4 0 4 0 4 0 4
		5 0 5 0 5 0 5 0
		0 5 0 5 0 5 0 5
		4 0 4 0 4 0 4 0
		0 3 0 3 0 3 0 3
		2 0 2 0 2 0 2 0
		0 1 0 1 0 1 0 1
