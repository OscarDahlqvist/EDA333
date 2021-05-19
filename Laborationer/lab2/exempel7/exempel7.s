#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		lui		t2, 0x8002
		lui		t4, 0x8002
		addi	t4, 20
loop:	lw		t3, 2(t2)
		addi	t2, t2, 4
		add		t1, t3, t1
		addi	t5, t5, 1
		addi	t6, t6, 1
		bne		t4, t2, loop
		nop
		
		.end	start