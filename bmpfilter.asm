.eqv HEADER_SIZE 54
	.data

file_buffer: .space 4
file_buffer_copy: .space 4
	
header: 
	.align 2
	.space 54
start_message: .asciiz "Input bmp file name: "
read_error: .asciiz "File read failed"
out_name: .asciiz "out.bmp"
file_name: .ascii "monalisa.bmp"
median_array: .space 25
comma: .ascii ", "
	.text
	.globl main
	
#s0 = input file descriptor; s1 = output file descriptor; s3 = bitmap width; s4 = bitmap height; s5 = width + padding(bytes); s6 = file size in bytes (w/o header bytes)
	
main:
#welcome user
	li $v0, 4		
	la $a0, start_message
	syscall
	
#tbd	
	#li $v0, 8
	#la $a0, file_name	#input file name
	#li $a1, 64	
	#syscall
	
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
	addiu $s6, $s6, -54
	lw $s3, header+16	# s3 = bitmap width
	lw $s4, header+20	# s4 = bitmap height
	
#temp###read file size in bytes
	li $v0, 1
	move $a0, $s6
	#syscall
	
	li $v0, 1
	move $a0, $s3
	#syscall
	
	li $v0, 1
	move $a0, $s4
	#syscall
	li $s7, 0
########

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

#######################################
#s1 = output file descriptor; s3 = bitmap width - 2; s4 = bitmap height - 2; s5 = bytes per row;
	addiu $s3, $s3, -2	#s3 = bitmap width - 2
	addiu $s4, $s4, -2	#s4 = bitmap height - 2
	
	li $a0, 2		#start y = 2
	li $a1, 2		#start x = 2
	li $a2, 0		#color: 0 -> B, 1 -> G, 2 -> R
next_row:
	li $a1, 2
next_col:
	li $a2, 0
	
filter_pixel:
#a0 - y; a1 - x; a2 = color
	#li $s0, 0		#s0 - sum of color values
	#addiu $a0, $a0,-2		#move to (0,0)
	#addiu $a1, $a1, -2		#move to (0,0)

loop:
	lw $t7, file_buffer
	mul $t8, $s5, $a0	#t8 = bytes per row * y
	mul $t9, $a1, 3		#t9 = 3*x
	addu $t8, $t8, $t9	#t8 = 3*x + bytes per row * y
	addu $t8, $t8, $a2	#t8 = 3*x + bytes per row * y + color offset
	addu $t7, $t8, $t7	#t7 = pixel address to save (file_buffer)	
	
	addiu $t1, $a0, -2
	addiu $t2, $a1, -2
	
	
	mul $t8, $s5, $t1	#t8 = bytes per row * y
	mul $t9, $t2, 3		#t9 = 3*x
	addu $t8, $t8, $t9	#t8 = 3*x + bytes per row * y
	lw $t9, file_buffer_copy
	addu $t8, $t8, $a2	#t8 = 3*x + bytes per row * y + color offset
	addu $t8, $t8, $t9	#t8 = pixel address moved down left corner (file_buffer_copy)

load_median_array:
	lbu $t9, ($t8)		#load pixel color value
	li $t3, 0		#t3 = row counter
	li $t2, 0
median_array_loop:
	lbu $t1, ($t8)
	sb $t1, median_array($t2)	#load (0,x)
	addiu $t2, $t2, 1
	
	lbu $t1, 3($t8)
	sb $t1, median_array($t2) 	#load (1,x)
	addiu $t2, $t2, 1
	
	lbu $t1, 6($t8)
	sb $t1, median_array($t2)	#load (2,x)
	addiu $t2, $t2, 1

	lbu $t1, 9($t8)
	sb $t1, median_array($t2)	#load (3,x)
	addiu $t2, $t2, 1
	
	lbu $t1, 12($t8)
	sb $t1, median_array($t2)	#load (4,x)
	addiu $t2, $t2, 1
	
	addu $t8, $t8, $s5		#a0 -> (0,x+1)
	addiu $t3, $t3, 1
	bne $t3, 5, median_array_loop




sort_array:
	la $t0, median_array
	addiu $t0, $t0, 24	#check
outer_loop:
	li $t1, 0
	la $t4, median_array
inner_loop:
	lbu $t2, 0($t4)
	lbu $t3 1($t4)
	ble $t2, $t3, continue
	li $t1, 1
	sb $t2, 1($t4)
	sb $t3, 0($t4)
continue:
	addiu $t4, $t4, 1
	bne $t4, $t0, inner_loop
	bne $t1, $zero, outer_loop

#calculate average color value
	li $t0, 5 	#array element offset (index)
	li $t1, 0	#sum
	
calculate_avg:
	lbu $t2, median_array($t0)	#load element
	add $t1, $t1, $t2	#add element to sum
	addiu $t0, $t0, 1
	bne $t0, 20, calculate_avg


return_avg:
	divu $t1, $t1, 15	#return average
	sb $t1, ($t7)		#store pixel
	beq $s7, 1, exit
	addiu $a2, $a2, 1	#increment color offset
	blt $a2, 3, loop
	addiu $a1, $a1, 1	#a1 - x
				#s4 - height -2
				#s3 - width -2
	li $a2, 0
	ble $a1, $s3, next_col
	addiu $a0, $a0, 1	#a0 - y
	ble $a0, $s4, next_row
	
	
	
	
	









####################################### 

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
