#ifndef STMT_DEF_H_
#define STMT_DEF_H_

#define STACK_CAPACITY 4096

/**
 * Associe à chaque instruction une pile pour les imbrications (ex: if dans un if)
*/
typedef struct {
	size_t stack[STACK_CAPACITY];
	size_t index; // index dans la pile
	size_t number; // numéro du de l'instruction
} _stack_statement_t;
typedef  _stack_statement_t stack_statement_t;

typedef enum { 
	SELECTION_IF = 0, 
	ITERATION_WHILE, 
	ITERATION_FOR
} type_statement_t;
/* Il peut y avoir aussi : SELECTION_SWITCH, ITERATION_FOR ... */
static stack_statement_t stmts[] = {
	[SELECTION_IF] = {{0}, 0, 0},
	[ITERATION_WHILE] = {{0}, 0, 0},
	[ITERATION_FOR] = {{0}, 0, 0}
};

#endif
