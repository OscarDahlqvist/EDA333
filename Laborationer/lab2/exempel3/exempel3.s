#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		addi	t1, zero, 0x1
		add		t2, t1, t1
		add		t3, t1, t1
		add		t4, t1, t1

		.end	start