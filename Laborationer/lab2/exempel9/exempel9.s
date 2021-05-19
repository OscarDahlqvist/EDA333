#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		addi	t2, zero, 200
		add		t1, zero, zero
loop:   add		t1, t1, t2
		addi	t2, t2, -1
		bnez	t2, loop
		nop
				
		.end	start
