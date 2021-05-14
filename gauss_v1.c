void eliminate (double **A, int N) { 
	int i, j, k; 
	k = 0;
	do { 				//forDiag
		for (j = k + 1; j < N; j++) { 		//forRightOf
			A[k][j] = A[k][j] / A[k][k];
		}

		A[k][k] = 1.0f;

		for (i = k + 1; i < N; i++) {		//forRightOf2
			for (j = k + 1; j < N; j++) {	//forAbove
				A[i][j] = A[i][j] - A[i][k] * A[k][j];
			}
			A[i][k] = 0.0; 
		} 
		k++
	} while(k<N)