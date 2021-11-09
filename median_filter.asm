.eqv HEADER_SIZE 54
	.data
#file_name: .space 64
file_name: .ascii "bmptest.bmp"
file_buffer: .space 800000
file_buffer_copy: .space 800000
start_message: .asciiz "Input bmp file name: "
read_error: .asciiz "File read failed"
out_name: .asciiz "out.bmp"
header: .space 54
median_array: .space 25
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
	

	
	lw $s3, header+18	# s3 = bitmap width
	lw $s4, header+22	# s4 = bitmap height
	
	abs $s4, $s4		#left-right, top-bottom
	
	mul $t0, $s3, 3		#width in bytes
	andi $t1, $t0, 3	#(width in bytes) % 4
	li $t2, 4
	subu $t3, $t2, $t1	# t3 = padding
	addu $s5, $t0, $t3	# s5 = width + padding
	mul $s6, $s5, $s4 	# s6 = number of pixels (with padding)
	
	li $v0, 14
	move $a0, $s0
	la $a1, file_buffer	#read input file pixel bytes
	li $a2, 799946	
	syscall
	
	li $v0, 16
	move $a0, $s0	#close file
	syscall

	li $t1, 0
	li $t2, 0

loop:
	beq $t1, 240000, write
	lb $t3, file_buffer($t2)
	li $t3, 255
	sb $t3, file_buffer($t2)
	addiu $t2, $t2, 3
	addiu $t1, $t1, 1
	j loop

load_med_array:	#a0 - current pixel color address
	lb $t0, ($a0)
	srl $t1, $s6, 1
	subu $a0, $a0, $t1	# move pixel up by two rows
	addiu $a0, $a0, -6	#move pixel left by two pixels, a0 -> (0,0)
	li $t2, 0 	#t2 = median_array index*4
	li $t3, 0	#t3 = row counter
loop_over_median_matrix:
	lb $t1, ($a0)
	sb $t1, median_array($t2)	#load (0,x)
	addiu $t2, $t2, 4
	
	lb $t1, 3($a0)
	sb $t1, median_array($t2) 	#load (1,x)
	addiu $t2, $t2, 4
	
	lb $t1, 6($a0)
	sb $t1, median_array($t2)	#load (2,x)
	addiu $t2, $t2, 4

	lb $t1, 9($a0)
	sb $t1, median_array($t2)	#load (3,x)
	addiu $t2, $t2, 4
	
	lb $t1, 12($a0)
	sb $t1, median_array($t2)	#load (4,x)
	addiu $t2, $t2, 4
	
	addu $a0, $a0, $s6		#a0 -> (0,x+1)
	addiu $t3, $t3, 1
	beq $t3, 5, sort_median_array
	j loop_over_median_matrix
	

	


write: li $v0, 15
	move $a0, $s1		#write pixel bytes to outfiledddddddddd
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
