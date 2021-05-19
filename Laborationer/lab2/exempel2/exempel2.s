#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		addi	t1, zero, 0x1
		addi	t2, zero, 0x2
		addi	t3, zero, 0x3
		add		t1, t1, t1
		add		t2, t2, t2
		add		t3, t3, t3
		add		t1, t1, t1
		add		t2, t2, t2
		add		t3, t3, t3
		
		.end	start