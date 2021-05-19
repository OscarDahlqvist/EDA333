#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		addi	t1, zero, 1
		addi	t2, zero, 1
		la		t5, x2
		addi	t3, zero, 10
L1:
		add		t4, t1, t2
		add		t1, t1, t2
		jal		store
		addi	t3, t3, -1
		bnez	t3, L1
		nop
		jal		promexit
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

store:
		jr		ra
		sw		t4, 0(t5)

x2:		
		.byte	1,2,3,4
		
		.end	start