	.data
file_buffer: .space 4
file_buffer_copy: .space 4
	
header: 
	.align 2
	.space 54
read_error: .asciiz "File read failed"
out_name: .asciiz "out.bmp"
file_name: .ascii "monalisa.bmp"
median_array: .space 25
	.text
	.globl main
				#s0 = input file descriptor; s1 = output file descriptor; s3 = bitmap width;
				#s4 = bitmap height; s5 = width + padding(bytes); s6 = file size in bytes (w/o header bytes)
	
main:
				#open input file
	li $v0, 13
	la $a0, file_name	
	li $a1, 0
	li $a2, 0
	syscall
	
	move $s0, $v0		#s0 = input file descriptor
	blt $s0, $zero, file_read_error
				#open outfile
	li $v0, 13
	la $a0, out_name	#create out.bmp
	li $a1, 1
	li $a2, 0
	syscall
	
	move $s1, $v0		#s1 = output file descriptor
	blt $s0, $zero, file_read_error
				#read input file first two bytes
	li $v0, 14
	move $a0, $s0
	la $a1, header		
	li $a2, 2	
	syscall
				#write first 2 bytes to outfile
	li $v0, 15
	move $a0, $s1		#write header to outfile
	la $a1, header	
	li $a2, 2
	syscall
				#read rest of 54-byte header
	li $v0, 14
	move $a0, $s0
	la $a1, header		#read input file header
	li $a2, 52	
	syscall
				#write rest of 54-byte header to outfile
	li $v0, 15
	move $a0, $s1		#write header to outfile
	la $a1, header	
	li $a2, 52
	syscall
				#get bmp size and dimensions
	lw $s6, header		# s6 = file size in bytes
	addiu $s6, $s6, -54	# s6 = pixel array size in bytes
	lw $s3, header+16	# s3 = bitmap width
	lw $s4, header+20	# s4 = bitmap height
				#dynamically allocate file buffers based on bmp size
	li $v0, 9 		#allocate buffer based on file size
	move $a0, $s6		
	syscall
	sw $v0, file_buffer	#store pointer in file_buffer
	li $v0, 9 		#allocate buffer copy based on file size
	move $a0, $s6		#
	syscall
	sw $v0, file_buffer_copy#store pointer in file_buffer_copy
				#remove possible minus from height
	abs $s4, $s4		#left-right, top-bottom
				#calculate padding and real byte width of bmp
	mul $t0, $s3, 3		#width in bytes
	andi $t1, $t0, 3	#(width in bytes) % 4
	li $t2, 4
	subu $t3, $t2, $t1	# t3 = padding
	andi $t3, $t3, 3	# t3 = padding

	addu $s5, $t0, $t3	# s5 = width + padding(bytes)
				#read input file pixel color bytes into file_buffer
	li $v0, 14
	move $a0, $s0
	lw $a1, file_buffer
	move $a2, $s6
	syscall
				#close input file
	li $v0, 16
	move $a0, $s0		#close file
	syscall
				#copy file buffer into copy buffer
	li $t0, 0
	lw $t1, file_buffer
	lw $t2 file_buffer_copy
copy_buffer_loop:
	lw $t3, ($t1)
	sw $t3, ($t2)
	addiu $t1, $t1, 4
	addiu $t2, $t2, 4
	addiu $t0, $t0, 4
	blt $t0, $s6, copy_buffer_loop
				#s1 = output file descriptor; s3 = bitmap width - 2; s4 = bitmap height - 2; s5 = bytes per row;
	addiu $s3, $s3, -2	#s3 = bitmap width - 2
	addiu $s4, $s4, -2	#s4 = bitmap height - 2
	li $a0, 2		#start x = 2
	li $a1, 2		#start y = 2
	li $a2, 0		#color offset: 0 -> B, 1 -> G, 2 -> R
	
next_row:
	li $a0, 2		#reset x
	
next_col:
	li $a2, 0		#reset color offset
	
filter_pixel:
	li $s0, 0		#s0 = sum of color values
	addiu $t1, $a0, -2 	#move to left down corner in pixel's 5x5 matrix (x)
	addiu $t0, $a1, -2	#move to left down corner in pixel's 5x5 matrix (y)
	
find_address:
	mul $t2, $t0, $s5	#t1 = y * bytes per row
	mul $t3, $t1, 3		#t3 = 3*x
	addu $t3, $t3, $t2	#t3 = 3*x + y * bytes per row
	addu $t3, $t3, $a2	#t3 = 3*x + y * bytes per row + color offset
	lw $t2, file_buffer
	addu $t3, $t3, $t2	#t3 = final pixel color address in file_buffer
	
calculate_pixel:
	li $t4, 0			#row counter
	li $t5, 0			#array index
	
load_array_loop:
	lbu $t2, ($t3)			#t2 = pixel color value (0, row counter)
	sb $t2, median_array($t5)	#store color value in array
	addiu $t5, $t5, 1		#increment index
	
	lbu $t2, 3($t3)			#t2 = pixel color value (1, row counter)
	sb $t2, median_array($t5)	#store color value in array
	addiu $t5, $t5, 1		#increment index
	
	lbu $t2, 6($t3)			#t2 = pixel color value (2, row counter)
	sb $t2, median_array($t5)	#store color value in array
	addiu $t5, $t5, 1		#increment index
	
	lbu $t2, 9($t3)			#t2 = pixel color value (3, row counter)
	sb $t2, median_array($t5)	#store color value in array
	addiu $t5, $t5, 1		#increment index
	
	lbu $t2, 12($t3)		#t2 = pixel color value (4, row counter)
	sb $t2, median_array($t5)	#store color value in array
	addiu $t5, $t5, 1		#increment index
	
	addu $t3, $t3, $s5		#go to next row
	addiu $t4, $t4, 1		#increment row counter
	blt $t4, 5, load_array_loop	#if not all 5 rows written, loop

sort_array:
	la $t2, median_array
	addiu $t2, $t2, 24		#last element address
outer_loop:
	li $t3, 0			#flag
	la $t4, median_array
	
inner_loop:
	lbu $t5, ($t4)
	lbu $t6, 1($t4)
	ble $t5, $t6, continue
	li $t3, 1			#if values swapped need another run
	sb $t5, 1($t4)
	sb $t6, ($t4)
	
continue:
	addiu $t4, $t4, 1
	bne $t4, $t2, inner_loop
	bne $t3, $zero, outer_loop
	
	li $t2, 5			#index offset
	li $t3, 0			#sum of color values
	
calculate_avg:
	lbu $t4, median_array($t2)
	addu $t3, $t3, $t4		#add element to sum
	addiu $t2, $t2, 1		#increment index
	bne $t2, 20, calculate_avg	#loop if not all 15 values are summed up
	divu $t4, $t3, 15		#calc average
	mul $t2, $a1, $s5	#t1 = y * bytes per row
	mul $t3, $a0, 3		#t3 = 3*x
	addu $t3, $t3, $t2	#t3 = 3*x + y * bytes per row
	addu $t3, $t3, $a2	#t3 = 3*x + y * bytes per row + color offset
	lw $t2, file_buffer
	addu $t3, $t3, $t2	#t3 = final pixel color address in file_buffer (actual pixel to modify)
	sb $t4, ($t3)		#write new pixel color value to file_buffer
	addiu $a2, $a2, 1	#increment color offset
	blt $a2, 3, find_address#loop for remaining colors
	addiu $a0, $a0, 1	#increment x coordinate
	ble $a0, $s3, next_col	#next column if x <= width - 2
	addiu $a1, $a1, 1	#increment y
	ble $a1, $s4, next_row	#next row if y <= height - 2 and x <= width - 2

write: 
	li $v0, 15
	move $a0, $s1		#write file_buffer to outfile
	lw $a1, file_buffer
	move $a2, $s6
	syscall

	li $v0, 16
	move $a0, $s1		#close file
	syscall
	
exit:
	li $v0, 10		#exit
	syscall

file_read_error:
	li $v0, 4
	la $a0, read_error
	syscall
	
	
	
	
	
