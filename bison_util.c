#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <bison_util.h>

/*
 * Pas utilisé car le type d'une est symbolisé par symbol_type qui est dans
 * le fichier types.h
*/
int is_same_type(size_t size_args, type_synth_expression $1, type_synth_expression $3, ...) {
	va_list args;
	va_start(args, $3);
	int found = 0;
	type_synth_expression type;
	for (int i = 0; i < size_args; i++) {
		type = (type_synth_expression) va_arg(args, type_synth_expression);
		if ($1 == type && $3 == type) {
			found = 1;
			break;
		}
	}
	va_end(args);
	// fprintf(file, "found %d\n", found);
	return found;
}
	
char *replace_word(const char* s, const char* old_w, const char* new_w)
{
	char* result;
	int i, cnt = 0;
	int new_wlen = strlen(new_w);
	int old_wlen = strlen(old_w);
	
	// Counting the number of times old word occur in the string
	for (i = 0; s[i] != '\0'; i++) {
		if (strstr(&s[i], old_w) == &s[i]) {
			cnt++;
			// Jumping to index after the old word.
			i += old_wlen - 1;
		}
	}
	
	// Making new string of enough length
	result = (char*)malloc(i + cnt * (new_wlen - old_wlen) + 1);

	i = 0;
	while (*s) {
		// compare the substring with the result
		if (strstr(s, old_w) == s) {
			strcpy(&result[i], new_w);
			i += new_wlen;
			s += old_wlen;
		}
		else
			result[i++] = *s++;
	}
	result[i] = '\0';
	
	return result;
}
	
struct stack_strings_t *new_stack_strings(void) {
	struct stack_strings_t *stack_strings = malloc(sizeof *stack_strings);
	if (stack_strings) {
		stack_strings->head = NULL;
		stack_strings->stack_strings_size = 0;
	}
	return stack_strings;
}
	
char *stack_strings_copy_string(const char *str) {
	char *tmp = malloc(strlen(str) + 1);
	if (tmp)
		strcpy(tmp, str);
	return tmp;
}
	
void stack_strings_push(struct stack_strings_t *the_stack_strings, const char *value) {
	struct stack_strings_entry *entry = malloc(sizeof *entry); 
	if (entry) {
		entry->data = stack_strings_copy_string(value);
		entry->next = the_stack_strings->head;
		the_stack_strings->head = entry;
		the_stack_strings->stack_strings_size++;
	}
	else {
		fprintf(stderr, "Error push in stack_strings\n");
	}
}
	
char *stack_strings_top(struct stack_strings_t *the_stack_strings) {
	if (the_stack_strings && the_stack_strings->head)
		return the_stack_strings->head->data;
	else
		return NULL;
}
	
void stack_strings_pop(struct stack_strings_t *the_stack_strings) {
	if (the_stack_strings->head != NULL) {
		struct stack_strings_entry *tmp = the_stack_strings->head;
		the_stack_strings->head = the_stack_strings->head->next;
		free(tmp->data);
		free(tmp);
		the_stack_strings->stack_strings_size--;
	}
}
	
void stack_strings_clear(struct stack_strings_t *the_stack_strings) {
	while (the_stack_strings->head != NULL)
		stack_strings_pop(the_stack_strings);
}
	
void stack_strings_destroy(struct stack_strings_t **the_stack_strings) {
	stack_strings_clear(*the_stack_strings);
	free(*the_stack_strings);
	*the_stack_strings = NULL;
}
	
struct stack_strings_entry *stack_strings_search_entry(
	struct stack_strings_t *the_stack_strings, const char *name) {
	struct stack_strings_entry *sse = NULL;
	for (sse = the_stack_strings->head;
		sse != NULL && strcmp(sse->data, name);
		sse = sse->next);
	return sse;
}
	
/*
int concatenate_msg(char *buffer, int length_response, size_t size_buffer, const char *msg) {
	return snprintf(buffer + length_response, size_buffer, "%s", msg);;
}
*/

// src : https://stackoverflow.com/questions/2736753/how-to-remove-extension-from-file-name
void remove_extension(char* s) {
	char* dot = 0;
	while (*s) {
		if (*s == '.') dot = s;  // last dot
		else if (*s == '/' || *s == '\\') dot = 0;  // ignore dots before path separators
		s++;
	}
	if (dot) *dot = '\0';
}
	
void symbol_print(symbol_table_entry *ste) {
	if (ste == NULL) return;
	printf("================================================\n");
	printf("name : %s\n", ste->name);
	printf("add : %u\n", ste->add);
	printf("nParams : %lu\n", ste->nParams);
	printf("Number of local variable(s) : %lu\n", ste->nLocalVariables);
	printf("Type of variable or return function : ");
	switch (ste->desc[0]) {
		case VOID_T :
			printf("void\n");
			break;
		case INT_T :
			printf("int\n");
			break;
		case BOOL_T :
			printf("boolean\n");
			break;
		case STRING_T :
			printf("string\n");
			break;
		case ERROR_T :
			printf("error_type\n");
			break;
		case INT_T_LVALUE :
			printf("int value\n");
			break;
		case BOOL_T_LVALUE :
			printf("boolean value\n");
			break;
		case STRING_T_LVALUE :
			printf("string value\n");
			break;
		default :
			printf("none\n");
	}
	printf("Class : ");
	switch (ste->class) {
		case GLOBAL_VARIABLE :
			printf("global variable\n");
			break;
		case LOCAL_VARIABLE :
			printf("local variable\n");
			break;
		case FUNCTION :
			printf("function\n");
			break;
		default :
			printf("none\n");
	}
	printf("================================================\n");
}
	
void vout(const char *format, ...) {
	va_list arg_ptr;
	va_start(arg_ptr, format);
	vprintf(format, arg_ptr);
	va_end(arg_ptr);
}
/*
int main() {
	return EXIT_SUCCESS;
}*/
