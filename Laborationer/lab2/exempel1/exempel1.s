#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		
		addi	t1, t2, 0x20
		nop
		nop
		nop
		nop
		
		sw		t1, -24(sp)
		nop
		nop
		nop
		nop
		
		lw		t2, -24(sp)
		nop
		nop
		nop
		nop
		
		beqz	zero, exit
		nop
		nop
		nop
		nop
		
		add		t0, t0, t0
		add		t0, t0, t0
		add		t0, t0, t0
		add		t0, t0, t0
		
exit:	nop
		nop
		nop
		nop

		.end start					# Marks the end of the program