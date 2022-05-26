#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <flex_util.h>
	
void string_to_int(int *r, const char *s) {
	char *p;
	long v;
	errno = 0;
	v = strtol(s, &p, 10);
	if ( ( *p != '\0'
		|| ( errno == ERANGE && ( v == LONG_MIN || v == LONG_MAX ) ) ) 
		|| ( v < INT_MIN || v > INT_MAX ) ) {
	fprintf(stderr, "Error converting string to int\n");
	exit(EXIT_FAILURE);
	}
	*r = v;
}
/*
int main() {
	return EXIT_SUCCESS;
}*/
	
	
