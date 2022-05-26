#ifndef _LABEL_H
#define _LABEL_H
#include <stddef.h>

unsigned int new_label_number();
void create_label(char *buf, size_t buf_size, const char *format, ...);
void fail_with(const char *format, ...);

#endif
