#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point

start:
	
		li		s0,9				# Initialize outer loop
		move	s1,s0				# Initialize inner loop
outer:
		la		s2,x+40	 			# Load adress of the last element
inner:
		lw		s4,-4(s2)			# Load Array[s1-1]
		lw		s5,-8(s2)           # Load Array[s1-2]
		
		nop							# (Delayed Load Slot s5)
		
		slt		s6,s4,s5			# Compare Array[s1-1] with Array[s1-2]
		beq		s6,zero,not_less
		addu	s1,s1,-1			# Decrease inner loop counter (Delayed Branch Slot)
		
		sw		s4,-8(s2)			# If less, swap places
		sw		s5,-4(s2)
		
not_less:
		
		bne		s1,zero,inner		# Continue inner loop if s0 < s1
		addu	s2,s2,-4			# Decrease address pointer (Delayed Branch Slot)
		
		addu	s0,s0,-1			# Increase outer loop counter
		bne		s0,zero,outer		# Continue outer loop if s1 < 10
		move	s1,s0				# Initialize inner loop (Delayed Branch Slot)
		
		addu	s2,s2,-36			# Load adress of first element
		la		s6,y				# Load adress of first element
		
		li		s1,222
		sw		s1,36(s6)

		li		s0,9				# Initialize outer loop
outer2:
		lw		s1,0(s2)
		addu	s2,s2,4				# Increase address pointer (Delayed Load Slot s1)
		sw		s1,0(s6)
		addu	s6,s6,4				# Increase address pointer
		
		bne		s0,zero,outer2		# Continue outer loop if s0 <= 10
		addu	s0,s0,-1			# Increase inner loop counter
				
		jal		promexit
		nop

x:		.word	10,9,8,7,6,5,4,3,2,1
y:		.word	 0,0,0,0,0,0,0,0,0,0
	
		.end	start
