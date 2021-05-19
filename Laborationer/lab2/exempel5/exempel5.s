#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		addi	t1, zero, 9
		add		t2, zero, zero
		add		t3, zero, zero
		add		t4, zero, zero
		add		t5, zero, zero
		add		t6, zero, zero
loop:	addi	t1, t1, -1
		addi	t2, t2, 1
		addi	t6, t6, 2
		bne		zero, t1, loop
		add		t3, t3, t2
		add		t4, t4, t2
		add		t5, t5, t2
		
		.end	start
		