.eqv HEADER_SIZE 54
	.data

file_buffer: .space 800000
file_buffer_copy: .space 800000
	
header: 
	.align 2
	.space 54
start_message: .asciiz "Input bmp file name: "
read_error: .asciiz "File read failed"
out_name: .asciiz "out.bmp"
file_name: .ascii "bmptest.bmp"
	.text
	.globl main
	
#s0 = input file descriptor; s1 = output file descriptor; s3 = bitmap width; s4 = bitmap height; s5 = width + padding(bytes);
	
main:
	li $v0, 4		#welcome user
	la $a0, start_message
	syscall
	
	#li $v0, 8
	#la $a0, file_name	#input file name
	#li $a1, 64	
	#syscall
	
	li $v0, 13
	la $a0, file_name	#open input file
	li $a1, 0
	li $a2, 0
	syscall
	
	move $s0, $v0		#s0 = input file descriptor
	blt $s0, $zero, file_read_error
	
	li $v0, 13
	la $a0, out_name	#create out.bmp
	li $a1, 1
	li $a2, 0
	syscall
	
	move $s1, $v0		#s1 = output file descriptor
	blt $s0, $zero, file_read_error
	
	li $v0, 14
	move $a0, $s0
	la $a1, header		#read input file header
	li $a2, 2	
	syscall
	
	##test write first 2 bytes to file
	li $v0, 15
	move $a0, $s1		#write header to outfile
	la $a1, header	
	li $a2, 2
	syscall
	##test
	li $v0, 14
	move $a0, $s0
	la $a1, header		#read input file header
	li $a2, 52	
	syscall
	##tset	
	li $v0, 15
	move $a0, $s1		#write header to outfile
	la $a1, header	
	li $a2, 52
	syscall
	

	lw $s3, header+16	# s3 = bitmap width
	lw $s4, header+20	# s4 = bitmap height
	
	
	abs $s4, $s4		#left-right, top-bottom
	
	mul $t0, $s3, 3		#width in bytes
	andi $t1, $t0, 3	#(width in bytes) % 4
	li $t2, 4
	subu $t3, $t2, $t1	# t3 = padding
	addu $s5, $t0, $t3	# s5 = width + padding(bytes)
	mul $s6, $s5, $s4 	# s6 = 
	mul $s6, $s6, 3	# s6 = number of bytes pixels (with padding)
	
	li $v0, 14
	move $a0, $s0
	la $a1, file_buffer	#read input file pixel bytes into file_buffer
	li $a2, 799946	
	syscall

	li $t0, 0

copy_buffer_loop:
	lw $t1, file_buffer($t0)
	sw $t1, file_buffer_copy($t0)
	addiu $t0, $t0, 4

	blt $t0, $s6, copy_buffer_loop




write: 
	li $v0, 15
	move $a0, $s1		#write file_buffer to outfile
	la $a1, file_buffer	
	li $a2, 799946
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