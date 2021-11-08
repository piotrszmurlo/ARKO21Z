.eqv HEADER_SIZE 54
	.data
#file_name: .space 64
file_name: .ascii "bmptest.bmp"
file_buffer: .space 150000
header: .space 54
start_message: .asciiz "Input bmp file name: "
read_error: .asciiz "File read failed"
out_name: .asciiz "out.bmp"
	.text
	.globl main
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
	li $a2, HEADER_SIZE	
	syscall
	
	li $v0, 15
	move $a0, $s1		#write header to outfile
	la $a1, header	
	li $a2, HEADER_SIZE
	syscall
	
	li $v0, 16
	move $a0, $s1
	syscall
	
	#lhu $s3, header+18	# s3 = bitmap width
	#lhu $s4, header+20
	
	li $v0, 10
	syscall
	
file_read_error:
	li $v0, 4
	la $a0, read_error
	syscall
	
exit:


	
