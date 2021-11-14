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
	syscall
	
	li $v0, 1
	move $a0, $s3
	syscall
	
	li $v0, 1
	move $a0, $s4
	syscall
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
