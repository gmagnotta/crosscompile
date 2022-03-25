#include <stdio.h>

int main(void) {

  printf("This application will calculate if a number is prime or not.\n");
  
  int n, i, c = 0;
  printf("Enter a number to check: ");
  scanf("%d", &n);

  //logic
  for (i = 1; i <= n; i++) {
      if (n % i == 0) {
         c++;
      }
  }

  if (c == 2) {
    printf("%d is a Prime number\n", n);
  } else {
    printf("%d is not a Prime number\n", n);
  }
  
  return 0;    
}
