#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		addi	t2, zero, 4
		jal		subr
		add		t3, zero, zero
		b		end
		add		t4, t3, zero
subr:	addi	t2, t2, -1
		beqz	t2, back
		addi	t3, t3, 1
		addi	sp, sp, -4
		sw		ra, 0(sp)
		jal		subr
		nop
		lw		ra, 0(sp)
		addi	sp, sp, 4
back:	jr		ra
		nop
		
end:	nop

		.end	start