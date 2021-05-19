# Bubble sort  a list of 11 numbers..

#include <iregdef.h>

		.data
nums:	.word	1, 6, 0, 8, 2, 3, 8, 8, 1, 3, 7	# the numbers to sort

		.text
		.globl	main
		.ent	main
main:
		move	t0, zero		# init outer loop counter
outer:
		sll		t4, t0, 2		# convert i to byte offset
		addi	t1, t0, 1		# init inner loop counter
inner:
		sll		t5, t1, 2		# convert j to byte offset
		lw		t2, nums(t4)	# load nums[i]
		lw		t3, nums(t5)	# load nums[j]
		bge		t3, t2, noswap	# compare them
		sw		t2, nums(t5)	# store nums[j] in nums[i]
		sw		t3, nums(t4)	# store nums[i] in nums[j]
noswap:	
		addi	t1, t1, 1		# increment inner loop counter
		bne		t1, 11, inner	# loop if less than 11
		addi	t0, t0, 1		# increment outer loop counter
		bne		t0, 10, outer	# loop if less than 10
		
		jr		ra				# return from main
		
		.end	main