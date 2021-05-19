# Read one integer from console, subtract one, and print result

#include <iregdef.h>

		.data
prompt:	.asciiz	"Gimme an integer: "
answer:	.asciiz	"Minus 1 = "

		.text
		.globl	main
		.ent	main
main:
		li		v0, 4			# print_string syscall code = 4
		la		a0, prompt		# string to print = prompt
		syscall					# call print_string
		li		v0, 5			# read_int syscall code = 5
		syscall					# call read_int
		addi	t0, v0, -1		# subtract 1
		li		v0, 4
		la		a0, answer 
		syscall					# print answer string
		move	a0, t0
		li		v0, 1
		syscall					# print result
		
		jr		ra				# return to main
		
		.end	main
