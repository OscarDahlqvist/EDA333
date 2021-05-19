#include <iregdef.h>

		.text
		.set	noreorder
		.globl	start				# The label should be globally known
		.ent	start				# The label marks an entry point
start:
		add		t1, zero, zero
		jal		subr
		addi	t1, t1, 2
		b		end
		add		t1, t1, t1 

subr:	addi	t1, t1, 1
		jr		ra

end:	nop
						
		.end	start
		