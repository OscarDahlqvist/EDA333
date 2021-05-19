#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		lui		t0, 0xBF90
		lw		t1, 0(t0)
		addi	t2, t1, 1
		addi	t3, t1, 1
		addi	t4, t1, 1
		
		.end	start