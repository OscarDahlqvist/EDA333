		#include <iregdef.h>

		.data
buffer:
		.space 101			# buffer for input string
prompt:
		.asciiz "Input string (max 100 characters): "
answer:
		.asciiz "Index of first 'b' is "

		.text               	# Start generating instructions
		.globl	main			# The label should be globally known
		.ent	main
		
main:	# start calls another procedure so we have to
		# allocate a stack frame and save registers
		addiu	sp, sp, -32		# allocate stack frame
		sw		ra, 20(sp)		# save return address
		sw		fp, 16(sp)		# save frame pointer
		addiu	fp, sp, 28		# new frame pointer
		li		v0, 4
		la		a0, prompt
		syscall					# request string input
		li		v0, 8
		la		a0, buffer
		li		a1, 101
		syscall					# read string and store in buffer
		la		a0, buffer
		jal		bfind			# call bfind with pointer to buffer
		la		t1, buffer
		sub		t0, v0, t1		# compute index of first 'b'
		li		v0, 4
		la		a0, answer
		syscall					# print answer string
		li		v0, 1
		move	a0, t0
		syscall					# print index of first 'b'
		
		lw		ra, 20(sp)		# restore return address
		lw		fp, 16(sp)		# restore frame pointer
		addiu	sp, sp, 32		# remove stack frame
		jr		ra				# return from main´
		
		.end	main
	

bfind:
		add		v0, zero, a0	# initialize return value to first char
		addiu	t0, zero, 98	# t0 = ASCII code for 'b'
loop:
		lbu		t1, 0(v0)		# t1 = next byte from string
		beq		t1, t0, ret		# return if it is a 'b'
		beq		t1, zero, ret	# return if it is the end of the string
		addi	v0, v0, 1		# point to next byte
		j		loop			# repeat loop
ret:
		jr		ra				# return to calling procedure
		
		
		
		

	



