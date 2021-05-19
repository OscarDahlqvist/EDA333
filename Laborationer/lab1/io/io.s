# io.s
#
# Testa in- och utmatning med syscall 22/23
# Thomas Lundqvist, 2001-02-03

#include <iregdef.h>

############################################################
# main - skriv ut alla tecken som matas in

		.text
		.globl main
main:
		addiu	sp, sp, -24		# allocate stack frame
		sw		ra, 16(sp)		# save return address

loop:	jal   get_char
		move  a0, v0
		jal   put_char
		b     loop

main_ret:
        lw    ra, 16(sp)		# restore return address
        addiu sp, sp, 24		# remove stack frame
        jr    ra				# return from main

############################################################
# get_char - l�s av ett tecken
#           V�ntar tills tecken finns tillg�ngligt.
#
# Returnerar:	$v0 = tecken som har l�sts av

        .text
        .globl get_char
get_char:
		addiu	sp, sp, -32		# allocate stack frame
        sw		v1, 4(sp)		# save $v1

getloop:	
		li		v0, 22
		syscall
		beqz	v0, getloop		# inget tecken tillg�ngligt �nnu
		
		move	v0, v1
		
		lw		v1,  4(sp)		# restore v1
		addiu	sp, sp, 32		# remove stack frame
		jr		ra
		
############################################################
# put_char - skriv ut ett tecken
#
# Args:	$a0 = tecken som ska skrivas ut

		.text
		.globl put_char
put_char:
		addiu	sp, sp, -32		# allocate stack frame
		sw		v0, 4(sp)		# save $v0
		
		li		v0, 23
		syscall
		
		lw		v0,  4(sp)		# restore v0
		addiu	sp, sp, 32		# remove stack frame
		jr		ra
