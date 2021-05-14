void eliminate (double **A, int N) { 
	float* ak
	float* akk
	float* aik
	float* akj
	float* aij
	float* akjMax
	float* aikMax
	float* akMax
	float* matrixEnd
	int rowSize
	int akkStep
	
	rowSize = N * sizeof(float)
	akkStep = rowSize + sizeof(float)
	
	ak = A
	akk = A
	matrixEnd = N*N*sizeof(float)
	akMax = matrixEnd - rowSize
	
	aikMax = matrixEnd
	
	do {
		akj = ak+rowSize
		do {
			akj -= sizeof(float)
			*akj /= *akk
		} while (akj != akk)

		*akk = 1
		
		aik = akk+rowSize
		akjMax = ak+rowSize
		
		do {
			aij = aik + 4
			akj = akk + 4
			do {
				*aij = *aij - *aik * *akj
				aij += sizeof(float)
				akj += sizeof(float)
			} while (akj != akjMax)
			*aik = 0.0f
			aik += rowSize
		} while (aik != aikMax)
			
		aik_max += sizeof(float)
		ak += sizeof(float)
		akk += akkStep
	} while (ak != akMax)
}
