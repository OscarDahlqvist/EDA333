### Text segment
		.text
start:
		la		$a0, matrix_24x24		# a0 = A (base address of matrix)
		li		$a1, 24  		    # a1 = N (number of elements per row)
		
		jal		eliminate
		nop
		jal 	exit
		
		#la		$a0, matrix_4x4		# a0 = A (base address of matrix)
		#li		$a1, 4  		    # a1 = N (number of elements per row)
									# <debug>
		jal 	print_matrix	    # print matrix before elimination
		nop							# </debug>
		jal 	eliminate			# triangularize matrix!
		nop							# <debug>
		jal 	print_matrix		# print matrix after elimination
		nop							# </debug>
		jal 	exit

exit:
		li   	$v0, 10          	# specify exit system call
      	syscall						# exit program

################################################################################
# eliminate - Triangularize matrix.
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N)
# <aliases>
.eqv A 			$a0
.eqv N 			$a1

.eqv CON1F		$f0 # for storing 1.0f
.eqv TMPF 		$f1 # temp float register
.eqv AKK_iV 	$f2 # 1/A[K][K]
.eqv AIK_V 		$f3 # Not used at the same time as AKK_iV, so nothing will be overwiden

.eqv AIJ_V 		$f4
.eqv AIJ_V2 	$f5 
.eqv AKJ_V 		$f6
.eqv AKJ_V2 	$f7
					# The register aliases of the following paragrph derives from the naive v1 implementation
.eqv NXTRW 		$t1	# points to the first item in the row after the current one being processed
.eqv AKK		$t2 # points to the &A[k][k] during doWhile_k
.eqv AKJ		$t3 # points to the &A[k][j] during doWhile_akj and doWhile_i
.eqv AIJ		$t4 # points to the &A[i][j] during doWhile_i 
.eqv AIK		$t5 # points to the &A[i][k] during doWhile_i
.eqv AIK_MAX	$t6	# AKJ_MAX != AKJ could be replaced with AKJ < AKJ_MAX, but I can use != since i know the increment steps (lt/gt check is slower)
#.eqv AKJ_MAX	$t7 # AIK_MAX != AIK could be replaced with AIK < AIK_MAX, -||-

.eqv RWSIZE 	$t8 # the number of bytes in a matrix row
.eqv AKKSTEP 	$t9 # the number of bytes you must offset to reach the (1 right, 1 down) diagonal from a given space
.eqv MATRIXEND 	$v0 # the first memory adress after the matrix
# </aliases>
eliminate:
		#<setup>
		sll RWSIZE, N, 2 				# RWSIZE = N*4 = N*sizeof(float)
		lwc1 CON1F, float1.0 			# CON1F = 1.0f
		addiu AKKSTEP, RWSIZE, 4		# AKKSTEP = RWSIZE + sizeof(float)
		
		move AKK, A						# AKK = A[0][0]
		add NXTRW, A, RWSIZE			# NXTRW = &A[1][0]
		mul $t0, N, N					# t0 = N*N = number of cells in matrix
		sll $t0, $t0, 2					# t0 = t0*4 = t0*sizeof(float) = number of bytes in matrix
		addu AIK_MAX, A, $t0 			#AIK_MAX = &A[N][0]	
		move MATRIXEND, AIK_MAX	  		#MATRIXEND = &A[N][0]
		#</setup>
		
		andi $t0, N, 1					#t0 = 1 if N is odd
		beq $t0, 1, eliminateSlow		
		andi $t0, A, 4 					#t0 = 4 if not double alligned
		beq $t0, 4, eliminateSlow

eliminateAllignedEven:
		#ONLY POSSIBLE FOR EVEN AND DOUBLE ALLIGNED MATRIXES
doWhile_k:			
			lwc1 TMPF, 0(AKK)
			move AKJ, AKK
			div.s AKK_iV, CON1F, TMPF	# AKK_iv = 1/A[K][K], Some precition is lost here
doWhile_akj:
				lwc1 TMPF, 0(AKJ)			# TMPF = M[AKJ]
				addiu AKJ, AKJ, 4			# akj += sizeof(float)
				mul.s TMPF, TMPF, AKK_iV	# TMPF = M[AKJ]*(1/M[AKK]) = A[K][J] / A[K][K]
doWhile_akj_CMP:
				bne AKJ, NXTRW, doWhile_akj
				swc1 TMPF, -4(AKJ)			# A[K][J] = TMPF = A[K][J] / A[K][K]
			
			swc1 CON1F, 0(AKK) 			
			
			addu AIK, AKK, RWSIZE		# AIK = AKK + RWSIZE (down 1 from AKK)	
			
doWhile_i:		
				lwc1 AIK_V, 0(AIK)
				
				#addiu AKJ_MAX, 4-ALIGN		commented out code which could, in combination with some other steps
				#addu AIJ, AIK, ALIGN		allow non double alligned even matrixes, but that technique would
				#addu AKJ, AKK, ALIGN		be slower
				
				andi AIJ, AIK, -5				# round down to nearest double alligned index (AIK & ~4) (~4 == -5)
				andi AKJ, AKK, -5				#  If rounded down this will result in AIK being overwritten with garbage.
												#  But this if fine since this adress will be overwritten with 0 on line 128
												
				addu AIK, AIK, RWSIZE			# AIK += RWSIZE (move AIK one space down)
				
doWhile_j:		
					ldc1 AKJ_V, 0(AKJ)	
					ldc1 AIJ_V, 0(AIJ)				
					mul.s TMPF, AIK_V, AKJ_V		# tmp = A[i][k] x A[k][j]
					sub.s AIJ_V, AIJ_V, TMPF		# AIJ[i][j] -= tmp
					mul.s TMPF, AIK_V, AKJ_V2		# tmp = A[i][k] x A[k][j+1]
					sub.s AIJ_V2, AIJ_V2, TMPF		# AIJ[i][j+1] -= tmp
					
					addiu AKJ, AKJ, 8				# AKJ += sizeof(float)*2
					
					sdc1 AIJ_V, 0(AIJ)				# A[i][j] = A[i][j] - A[i][k] * A[k][j]
													# A[i][j+1] = A[i][j+1] - A[i][k] * A[k][j+1]
		
doWhile_j_CMP:		bne AKJ, NXTRW, doWhile_j		# if AKJ overflowed to the next (aka wrong) row stop looping
					addiu AIJ, AIJ, 8				# AIJ += sizeof(int)
				
doWhile_i_CMP:	bne AIK, AIK_MAX, doWhile_i		# if AIK is outside the matrix (only checks at A[N][k] to improve code)
				sw $0, 0(NXTRW)					# AKJ will equal the first index of the next row since it overflowed
			
			#xori ALIGN, ALIGN, 4
			
			addu NXTRW, NXTRW, RWSIZE		# NXTRW += RWSIZE (1 down)
			addiu AIK_MAX, AIK_MAX, 4 		# AIK_MAX += sizeof(float)
doWhile_k_CMP:	
			bne NXTRW, MATRIXEND, doWhile_k	# no code need to be ran for the last row since we know it must be 0 .. 0 1 (as we assume the matrix is invertible)
			addu AKK, AKK, AKKSTEP			# AKK += AKKSTEP (right 1, down 1 from AKK)
			
		#29 words of code in the main loop, fits inside 32 words of I-Cache, very nice
			
		subu $t0, MATRIXEND, 4			# t0 <- adress of last item in matrix (bottom right)
		
		jr	 $ra						# return from subroutine
		swc1 CON1F, 0($t0)				# set last item in matrix to 1.0f
		
################################################################################
eliminateSlow:
elim2_k:			
			lwc1 TMPF, 0(AKK)
			add AKJ, AKK, 4				# start iterating from A[K][K+1]
			div.s AKK_iV, CON1F, TMPF	# AKK_iv = 1/A[K][K], Some precition is lost here
elim2_akj:
				lwc1 AKJ_V, 0(AKJ)			# tmp = A[K][J]
				addiu AKJ, AKJ, 4			# AKJ += sizeof(float)
				mul.s AKJ_V, AKJ_V, AKK_iV	# A[K][J] = A[K][J] / A[K][K]
elim2_akj_CMP:
				bne AKJ, NXTRW, elim2_akj
				swc1 AKJ_V, -4(AKJ)			# A[K][J] = TMPF = A[K][J] / A[K][K]
											#  -4 offset since AKJ has already been increased
			swc1 CON1F, 0(AKK)
			
			addu AIK, AKK, RWSIZE		# AIK = AKK + RWSIZE (down 1 from AKK)	
			
elim2_i:		
				lwc1 AIK_V, 0(AIK)
				
				addiu AIJ, AIK, 4
				addiu AKJ, AKK, 4
				sw $0, 0(AIK)				
elim2_j:		
					lwc1 AKJ_V, 0(AKJ)	
					lwc1 AIJ_V, 0(AIJ)				
					mul.s TMPF, AIK_V, AKJ_V		# tmp = A[i][k] x A[k][j]
					sub.s AIJ_V, AIJ_V, TMPF		# A[i][j] -= tmp					
					addiu AKJ, AKJ, 4				# AKJ += sizeof(float)				
					swc1 AIJ_V, 0(AIJ)				# A[i][j] = A[i][j] - A[i][k] * A[k][j]
		
elim2_j_CMP:		bne AKJ, NXTRW, elim2_j		# if AKJ overflowed to the next (aka wrong) row stop looping
					addiu AIJ, AIJ, 4			# AIJ += sizeof(float)
				
elim2_i_CMP:	bne AIK, AIK_MAX, elim2_i		# if AIK is outside the matrix (only checks at A[N][k] to improve efficiency)
				addu AIK, AIK, RWSIZE			# AIK += RWSIZE (move AIK one space down)
			
			addu NXTRW, NXTRW, RWSIZE		# NXTRW += RWSIZE (1 down)
			addiu AIK_MAX, AIK_MAX, 4 		# AIK_MAX += sizeof(float)
elim2_k_CMP:	
			bne NXTRW, MATRIXEND, elim2_k	# no code need to be ran for the last row since we know it must be 0 .. 0 1 (as we assume the matrix is invertible)
			addu AKK, AKK, AKKSTEP			# AKK += AKKSTEP (right 1, down 1 from AKK)
			
		subu $t0, MATRIXEND, 4			# t0 <- adress of last item in matrix (bottom right)
		jr	 $ra
		swc1 CON1F, 0($t0)				# set last item in matrix to 1.0f
		
################################################################################
# getElem - Get address and content of matrix element A[a][b].
#
# Argument registers $a0..$a3 are preserved across calls
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N)
#			$a2  - row number (a)
#			$a3  - column number (b)
#						
# Returns:	$v0  - Address to A[a][b]
#			$f0  - Contents of A[a][b] (single precision)
getElem:
		addiu	$sp, $sp, -12		# allocate stack frame
		sw		$s2, 8($sp)
		sw		$s1, 4($sp)
		sw		$s0, 0($sp)			# done saving registers
		
		sll		$s2, $a1, 2			# s2 = 4*N (number of bytes per row)
		multu	$a2, $s2			# result will be 32-bit unless the matrix is huge
		mflo	$s1					# s1 = a*s2
		addu	$s1, $s1, $a0		# Now s1 contains address to row a
		sll		$s0, $a3, 2			# s0 = 4*b (byte offset of column b)
		addu	$v0, $s1, $s0		# Now we have address to A[a][b] in v0...
		l.s		$f0, 0($v0)		    # ... and contents of A[a][b] in f0.
		
		lw		$s2, 8($sp)
		lw		$s1, 4($sp)
		lw		$s0, 0($sp)			# done restoring registers
		addiu	$sp, $sp, 12		# remove stack frame
		
		jr		$ra					# return from subroutine
		nop							# this is the delay slot associated with all types of jumps

################################################################################
# print_matrix
#
# This routine is for debugging purposes only. 
# Do not call this routine when timing your code!
#
# print_matrix uses floating point register $f12.
# the value of $f12 is _not_ preserved across calls.
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N) 
print_matrix:
		addiu	$sp,  $sp, -20		# allocate stack frame
		sw		$ra,  16($sp)
		sw      $s2,  12($sp)
		sw		$s1,  8($sp)
		sw		$s0,  4($sp) 
		sw		$a0,  0($sp)		# done saving registers

		move	$s2,  $a0			# s2 = a0 (array pointer)
		move	$s1,  $zero			# s1 = 0  (row index)
loop_s1:
		move	$s0,  $zero			# s0 = 0  (column index)
loop_s0:
		l.s		$f12, 0($s2)        # $f12 = A[s1][s0]
		li		$v0,  2				# specify print float system call
 		syscall						# print A[s1][s0]
		la		$a0,  spaces
		li		$v0,  4				# specify print string system call
		syscall						# print spaces

		addiu	$s2,  $s2, 4		# increment pointer by 4

		addiu	$s0,  $s0, 1        # increment s0
		blt		$s0,  $a1, loop_s0  # loop while s0 < a1
		nop
		la		$a0,  newline
		syscall						# print newline
		addiu	$s1,  $s1, 1		# increment s1
		blt		$s1,  $a1, loop_s1  # loop while s1 < a1
		nop
		la		$a0,  newline
		syscall						# print newline

		lw		$ra,  16($sp)
		lw		$s2,  12($sp)
		lw		$s1,  8($sp)
		lw		$s0,  4($sp)
		lw		$a0,  0($sp)		# done restoring registers
		addiu	$sp,  $sp, 20		# remove stack frame

		jr		$ra					# return from subroutine
		nop							# this is the delay slot associated with all types of jumps

### End of text segment

### Data segment 
		.data
		
### String constants
spaces:
		.asciiz "   "   			# spaces to insert between numbers
newline:
		.asciiz "\n"  				# newline

### Float constants
float1.0:
		.float 1.0
## Input matrix: (4x4) ##
		.word 0xdeadbeef
		.align 3
matrix_4x4:	
		.float 57.0
		.float 20.0
		.float 34.0
		.float 59.0
		
		.float 104.0
		.float 19.0
		.float 77.0
		.float 25.0
		
		.float 55.0
		.float 14.0
		.float 10.0
		.float 43.0
		
		.float 31.0
		.float 41.0
		.float 108.0
		.float 59.0
		
		# These make it easy to check if 
		# data outside the matrix is overwritten
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef
		.word 0xdeadbeef

## Input matrix: (24x24) ##
		.align 3
matrix_24x24:
		.float	 92.00 
		.float	 43.00 
		.float	 86.00 
		.float	 87.00 
		.float	100.00 
		.float	 21.00 
		.float	 36.00 
		.float	 84.00 
		.float	 30.00 
		.float	 60.00 
		.float	 52.00 
		.float	 69.00 
		.float	 40.00 
		.float	 56.00 
		.float	104.00 
		.float	100.00 
		.float	 69.00 
		.float	 78.00 
		.float	 15.00 
		.float	 66.00 
		.float	  1.00 
		.float	 26.00 
		.float	 15.00 
		.float	 88.00 

		.float	 17.00 
		.float	 44.00 
		.float	 14.00 
		.float	 11.00 
		.float	109.00 
		.float	 24.00 
		.float	 56.00 
		.float	 92.00 
		.float	 67.00 
		.float	 32.00 
		.float	 70.00 
		.float	 57.00 
		.float	 54.00 
		.float	107.00 
		.float	 32.00 
		.float	 84.00 
		.float	 57.00 
		.float	 84.00 
		.float	 44.00 
		.float	 98.00 
		.float	 31.00 
		.float	 38.00 
		.float	 88.00 
		.float	101.00 

		.float	  7.00 
		.float	104.00 
		.float	 57.00 
		.float	  9.00 
		.float	 21.00 
		.float	 72.00 
		.float	 97.00 
		.float	 38.00 
		.float	  7.00 
		.float	  2.00 
		.float	 50.00 
		.float	  6.00 
		.float	 26.00 
		.float	106.00 
		.float	 99.00 
		.float	 93.00 
		.float	 29.00 
		.float	 59.00 
		.float	 41.00 
		.float	 83.00 
		.float	 56.00 
		.float	 73.00 
		.float	 58.00 
		.float	  4.00 

		.float	 48.00 
		.float	102.00 
		.float	102.00 
		.float	 79.00 
		.float	 31.00 
		.float	 81.00 
		.float	 70.00 
		.float	 38.00 
		.float	 75.00 
		.float	 18.00 
		.float	 48.00 
		.float	 96.00 
		.float	 91.00 
		.float	 36.00 
		.float	 25.00 
		.float	 98.00 
		.float	 38.00 
		.float	 75.00 
		.float	105.00 
		.float	 64.00 
		.float	 72.00 
		.float	 94.00 
		.float	 48.00 
		.float	101.00 

		.float	 43.00 
		.float	 89.00 
		.float	 75.00 
		.float	100.00 
		.float	 53.00 
		.float	 23.00 
		.float	104.00 
		.float	101.00 
		.float	 16.00 
		.float	 96.00 
		.float	 70.00 
		.float	 47.00 
		.float	 68.00 
		.float	 30.00 
		.float	 86.00 
		.float	 33.00 
		.float	 49.00 
		.float	 24.00 
		.float	 20.00 
		.float	 30.00 
		.float	 61.00 
		.float	 45.00 
		.float	 18.00 
		.float	 99.00 

		.float	 11.00 
		.float	 13.00 
		.float	 54.00 
		.float	 83.00 
		.float	108.00 
		.float	102.00 
		.float	 75.00 
		.float	 42.00 
		.float	 82.00 
		.float	 40.00 
		.float	 32.00 
		.float	 25.00 
		.float	 64.00 
		.float	 26.00 
		.float	 16.00 
		.float	 80.00 
		.float	 13.00 
		.float	 87.00 
		.float	 18.00 
		.float	 81.00 
		.float	  8.00 
		.float	104.00 
		.float	  5.00 
		.float	 57.00 

		.float	 19.00 
		.float	 26.00 
		.float	 87.00 
		.float	 80.00 
		.float	 72.00 
		.float	106.00 
		.float	 70.00 
		.float	 83.00 
		.float	 10.00 
		.float	 14.00 
		.float	 57.00 
		.float	  8.00 
		.float	  7.00 
		.float	 22.00 
		.float	 50.00 
		.float	 90.00 
		.float	 63.00 
		.float	 83.00 
		.float	  5.00 
		.float	 17.00 
		.float	109.00 
		.float	 22.00 
		.float	 97.00 
		.float	 13.00 

		.float	109.00 
		.float	  5.00 
		.float	 95.00 
		.float	  7.00 
		.float	  0.00 
		.float	101.00 
		.float	 65.00 
		.float	 19.00 
		.float	 17.00 
		.float	 43.00 
		.float	100.00 
		.float	 90.00 
		.float	 39.00 
		.float	 60.00 
		.float	 63.00 
		.float	 49.00 
		.float	 75.00 
		.float	 10.00 
		.float	 58.00 
		.float	 83.00 
		.float	 33.00 
		.float	109.00 
		.float	 63.00 
		.float	 96.00 

		.float	 82.00 
		.float	 69.00 
		.float	  3.00 
		.float	 82.00 
		.float	 91.00 
		.float	101.00 
		.float	 96.00 
		.float	 91.00 
		.float	107.00 
		.float	 81.00 
		.float	 99.00 
		.float	108.00 
		.float	 73.00 
		.float	 54.00 
		.float	 18.00 
		.float	 91.00 
		.float	 97.00 
		.float	  8.00 
		.float	 71.00 
		.float	 27.00 
		.float	 69.00 
		.float	 25.00 
		.float	 77.00 
		.float	 34.00 

		.float	 36.00 
		.float	 25.00 
		.float	  8.00 
		.float	 69.00 
		.float	 24.00 
		.float	 71.00 
		.float	 56.00 
		.float	106.00 
		.float	 30.00 
		.float	 60.00 
		.float	 79.00 
		.float	 12.00 
		.float	 51.00 
		.float	 65.00 
		.float	103.00 
		.float	 49.00 
		.float	 36.00 
		.float	 93.00 
		.float	 47.00 
		.float	  0.00 
		.float	 37.00 
		.float	 65.00 
		.float	 91.00 
		.float	 25.00 

		.float	 74.00 
		.float	 53.00 
		.float	 53.00 
		.float	 33.00 
		.float	 78.00 
		.float	 20.00 
		.float	 68.00 
		.float	  4.00 
		.float	 45.00 
		.float	 76.00 
		.float	 74.00 
		.float	 70.00 
		.float	 38.00 
		.float	 20.00 
		.float	 67.00 
		.float	 68.00 
		.float	 80.00 
		.float	 36.00 
		.float	 81.00 
		.float	 22.00 
		.float	101.00 
		.float	 75.00 
		.float	 71.00 
		.float	 28.00 

		.float	 58.00 
		.float	  9.00 
		.float	 28.00 
		.float	 96.00 
		.float	 75.00 
		.float	 10.00 
		.float	 12.00 
		.float	 39.00 
		.float	 63.00 
		.float	 65.00 
		.float	 73.00 
		.float	 31.00 
		.float	 85.00 
		.float	 31.00 
		.float	 36.00 
		.float	 20.00 
		.float	108.00 
		.float	  0.00 
		.float	 91.00 
		.float	 36.00 
		.float	 20.00 
		.float	 48.00 
		.float	105.00 
		.float	101.00 

		.float	 84.00 
		.float	 76.00 
		.float	 13.00 
		.float	 75.00 
		.float	 42.00 
		.float	 85.00 
		.float	103.00 
		.float	100.00 
		.float	 94.00 
		.float	 22.00 
		.float	 87.00 
		.float	 60.00 
		.float	 32.00 
		.float	 99.00 
		.float	100.00 
		.float	 96.00 
		.float	 54.00 
		.float	 63.00 
		.float	 17.00 
		.float	 30.00 
		.float	 95.00 
		.float	 54.00 
		.float	 51.00 
		.float	 93.00 

		.float	 54.00 
		.float	 32.00 
		.float	 19.00 
		.float	 75.00 
		.float	 80.00 
		.float	 15.00 
		.float	 66.00 
		.float	 54.00 
		.float	 92.00 
		.float	 79.00 
		.float	 19.00 
		.float	 24.00 
		.float	 54.00 
		.float	 13.00 
		.float	 15.00 
		.float	 39.00 
		.float	 35.00 
		.float	102.00 
		.float	 99.00 
		.float	 68.00 
		.float	 92.00 
		.float	 89.00 
		.float	 54.00 
		.float	 36.00 

		.float	 43.00 
		.float	 72.00 
		.float	 66.00 
		.float	 28.00 
		.float	 16.00 
		.float	  7.00 
		.float	 11.00 
		.float	 71.00 
		.float	 39.00 
		.float	 31.00 
		.float	 36.00 
		.float	 10.00 
		.float	 47.00 
		.float	102.00 
		.float	 64.00 
		.float	 29.00 
		.float	 72.00 
		.float	 83.00 
		.float	 53.00 
		.float	 17.00 
		.float	 97.00 
		.float	 68.00 
		.float	 56.00 
		.float	 22.00 

		.float	 61.00 
		.float	 46.00 
		.float	 91.00 
		.float	 43.00 
		.float	 26.00 
		.float	 35.00 
		.float	 80.00 
		.float	 70.00 
		.float	108.00 
		.float	 37.00 
		.float	 98.00 
		.float	 14.00 
		.float	 45.00 
		.float	  0.00 
		.float	 86.00 
		.float	 85.00 
		.float	 32.00 
		.float	 12.00 
		.float	 95.00 
		.float	 79.00 
		.float	  5.00 
		.float	 49.00 
		.float	108.00 
		.float	 77.00 

		.float	 23.00 
		.float	 52.00 
		.float	 95.00 
		.float	 10.00 
		.float	 10.00 
		.float	 42.00 
		.float	 33.00 
		.float	 72.00 
		.float	 89.00 
		.float	 14.00 
		.float	  5.00 
		.float	  5.00 
		.float	 50.00 
		.float	 85.00 
		.float	 76.00 
		.float	 48.00 
		.float	 13.00 
		.float	 64.00 
		.float	 63.00 
		.float	 58.00 
		.float	 65.00 
		.float	 39.00 
		.float	 33.00 
		.float	 97.00 

		.float	 52.00 
		.float	 18.00 
		.float	 67.00 
		.float	 57.00 
		.float	 68.00 
		.float	 65.00 
		.float	 25.00 
		.float	 91.00 
		.float	  7.00 
		.float	 10.00 
		.float	101.00 
		.float	 18.00 
		.float	 52.00 
		.float	 24.00 
		.float	 90.00 
		.float	 31.00 
		.float	 39.00 
		.float	 96.00 
		.float	 37.00 
		.float	 89.00 
		.float	 72.00 
		.float	  3.00 
		.float	 28.00 
		.float	 85.00 

		.float	 68.00 
		.float	 91.00 
		.float	 33.00 
		.float	 24.00 
		.float	 21.00 
		.float	 67.00 
		.float	 12.00 
		.float	 74.00 
		.float	 86.00 
		.float	 79.00 
		.float	 22.00 
		.float	 44.00 
		.float	 34.00 
		.float	 47.00 
		.float	 25.00 
		.float	 42.00 
		.float	 58.00 
		.float	 17.00 
		.float	 61.00 
		.float	  1.00 
		.float	 41.00 
		.float	 42.00 
		.float	 33.00 
		.float	 81.00 

		.float	 28.00 
		.float	 71.00 
		.float	 60.00 
		.float	101.00 
		.float	 75.00 
		.float	 89.00 
		.float	 76.00 
		.float	 34.00 
		.float	 71.00 
		.float	  0.00 
		.float	 58.00 
		.float	 92.00 
		.float	 68.00 
		.float	 70.00 
		.float	 57.00 
		.float	 44.00 
		.float	 39.00 
		.float	 79.00 
		.float	 88.00 
		.float	 74.00 
		.float	 16.00 
		.float	  3.00 
		.float	  6.00 
		.float	 75.00 

		.float	 20.00 
		.float	 68.00 
		.float	 77.00 
		.float	 62.00 
		.float	  0.00 
		.float	  0.00 
		.float	 33.00 
		.float	 28.00 
		.float	 72.00 
		.float	 94.00 
		.float	 19.00 
		.float	 37.00 
		.float	 73.00 
		.float	 96.00 
		.float	 71.00 
		.float	 34.00 
		.float	 97.00 
		.float	 20.00 
		.float	 17.00 
		.float	 55.00 
		.float	 91.00 
		.float	 74.00 
		.float	 99.00 
		.float	 21.00 

		.float	 43.00 
		.float	 77.00 
		.float	 95.00 
		.float	 60.00 
		.float	 81.00 
		.float	102.00 
		.float	 25.00 
		.float	101.00 
		.float	 60.00 
		.float	102.00 
		.float	 54.00 
		.float	 60.00 
		.float	103.00 
		.float	 87.00 
		.float	 89.00 
		.float	 65.00 
		.float	 72.00 
		.float	109.00 
		.float	102.00 
		.float	 35.00 
		.float	 96.00 
		.float	 64.00 
		.float	 70.00 
		.float	 83.00 

		.float	 85.00 
		.float	 87.00 
		.float	 28.00 
		.float	 66.00 
		.float	 51.00 
		.float	 18.00 
		.float	 87.00 
		.float	 95.00 
		.float	 96.00 
		.float	 73.00 
		.float	 45.00 
		.float	 67.00 
		.float	 65.00 
		.float	 71.00 
		.float	 59.00 
		.float	 16.00 
		.float	 63.00 
		.float	  3.00 
		.float	 77.00 
		.float	 56.00 
		.float	 91.00 
		.float	 56.00 
		.float	 12.00 
		.float	 53.00 

		.float	 56.00 
		.float	  5.00 
		.float	 89.00 
		.float	 42.00 
		.float	 70.00 
		.float	 49.00 
		.float	 15.00 
		.float	 45.00 
		.float	 27.00 
		.float	 44.00 
		.float	  1.00 
		.float	 78.00 
		.float	 63.00 
		.float	 89.00 
		.float	 64.00 
		.float	 49.00 
		.float	 52.00 
		.float	109.00 
		.float	  6.00 
		.float	  8.00 
		.float	 70.00 
		.float	 65.00 
		.float	 24.00 
		.float	 24.00 

### End of data segment