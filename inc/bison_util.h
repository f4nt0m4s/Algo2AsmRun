#ifndef _BISON_UTIL_H
#define _BISON_UTIL_H
#include <stddef.h>
#include <synthesized_type_expression.h>
#include <types.h>

int is_same_type(size_t size_args, type_synth_expression $1, type_synth_expression $3, ...);

/**
 * Source : https://www.geeksforgeeks.org/c-program-replace-word-text-another-given-word/
 * Example :
 * char str[] = "fichier.tex";
 * char old[] = ".tex";
 * char new[] = ".asm";
 * char* result = NULL;
 * result = replace_word(str, old, new);
 * printf("New String: %s\n", result);
 * free(result);
*/
char *replace_word(const char* s, const char* old_w, const char* new_w);

/**
 * Stack of strings (used for the stack_strings of package_name)
 * Source : https://stackoverflow.com/questions/1919975/creating-a-stack-of-strings-in-c
 * Example :
 * struct stack_strings_t *the_stack_strings = new_stack_strings();
 * char *data;
 * push(the_stack_strings, "test1");
 * push(the_stack_strings, "test2");
 * struct stack_entry *sse = NULL;
 * sse = search_stack_strings_entry(the_stack, "test1");
 * if (sse != NULL) {
 *     printf("found %s\n", sse->data);
 * }
 * data = top(the_stack_strings);
 * printf("%s\n", data);
 * pop(the_stack_strings);
 * data = top(the_stack_strings);
 * printf("%s\n", data);
 * clear(the_stack_strings);
 * destroy_stack_strings(&the_stack_strings);
*/
struct stack_strings_entry {
	char *data;
	struct stack_strings_entry *next;
};
struct stack_strings_t {
	struct stack_strings_entry *head;
	size_t stack_strings_size;
};
struct stack_strings_t *new_stack_strings(void);
char *stack_strings_copy_string(const char *str);
void stack_strings_push(struct stack_strings_t *the_stack_strings, const char *value);
char *stack_strings_top(struct stack_strings_t *the_stack_strings);
void stack_strings_pop(struct stack_strings_t *the_stack_strings);
void stack_strings_clear(struct stack_strings_t *the_stack_strings);
void stack_strings_destroy(struct stack_strings_t **the_stack_strings);
struct stack_strings_entry *stack_strings_search_entry(struct stack_strings_t 
*the_stack_strings, const char *name);
int concatenate_msg(char *buffer, size_t size_buffer, const char *msg);
void remove_extension(char* s);
void symbol_print(symbol_table_entry *ste);
void vout(const char *format, ...);
#endif
