int main(int argc, char *argv[])
{
  int a[10][10], b[10][10], c[10][10];
  int i, j;

  for (i = 1; i <= 10; i++)
    for (j = 1; j <= 10; j++)
      c[i - 1][j - 1] = a[i - 1][j - 1] + b[i - 1][j - 1];
}