/* $begin 010-multmain-c */
#include <stdio.h>

void multstore(long, long, long *);

int main() {
    long d;
	float test;
	test=2.468;
    printf("2 * 3 --> %ld\ntest: %f\n", d,test);
    multstore(2, 3, &d);
    printf("2 * 3 --> %ld\n", d);
    printf("2 * 3 --> %ld\n", d);
    return 0;
}

long mult2(long a, long b) {
    long s = a * b;
    return s;
 }
/* $end 010-multmain-c */

