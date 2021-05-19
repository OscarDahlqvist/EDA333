#define N 102
#define M 10

main(int argc, char *argv[])
{
	int i, j, f[N];
	
	for (j=0; j<M; j++) {
		f[0] = 1;
		f[1] = 1;
		for (i=2; i<N; i++) {
			f[i] = f[i-1] + f[i-2];
		}
	}
	printf("\n%d\n",f[N-1]);
}
