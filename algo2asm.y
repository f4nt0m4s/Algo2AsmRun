%{
	#include <ctype.h>
	#include <stdlib.h>
	#include <stdio.h>
	#include <stdbool.h>
	#include <stdarg.h>
	#include <string.h>
	#include <strings.h>
	#include <math.h>
	#include <limits.h>
	#include <libgen.h>
	#include <types.h>
	#include <stable.h>
	#include <label.h>
	#include <bison_util.h>
	#include <stack_stmt_def.h>
	int yylex(void);
	void yyerror(const char *msg_error);
	#define BUFFER_SIZE_MAX 256
	#define MAX_VARNAME 64
	#define BUFFER_SIZE_TABLE_SYMBOLS_MAX 4096
	// Lecture du fichier yyin et sortie du code assembleur sur yyout
	extern FILE *yyin;
	extern FILE *yyout;
	const char *filename_parse = NULL;
	char filename_out[FILENAME_MAX];
	// Label de la division par zéro
	char lbl_string_errordiv[BUFFER_SIZE_MAX];
	/**
	 * Pile de string contenant le nom des paquetages
	 * La pile de paquetage sert à éviter les cas de croisement de
	 paquetage exemple :
	 \BEGIN{paquetage1} ...\BEGIN{paquetage2} 
	 ...\END{paquetage1} ... \END{paquetage2}
	 * forme autorisé :
	 \BEGIN{paquetage1} ...\END{paquetage1 
	 \BEGIN{paquetage2} ... \END{paquetage2}
	*/
	struct stack_strings_t *stack_packages = NULL;
	// Nom de la fonction
	const char *function_name = NULL;
	// Format des variables
	#define FORMAT_ASIPRO_LABEL_VAR "var:"
	#define DEFAULT_ASIPRO_VAR_VALUE 0
	/**
	 * Liste des fonctionnalités
	 * Fonction :
	 	Sans argument :
	 		\BEGIN{algo}{function_name}{}
	 	Avec arguments :
	 		\BEGIN{algo}{function_name}{param1,param2}
	 * Instructions (Statement)
	 	Conditions :
	 		\IF {expression} code
	 		\IF {expression} code \ELSE code
	 	Boucles :
	 		\DOWHILE{expression} code
	 		\DOFORI{identifier}{expression}{expression} code
	 	Affectations :
	 		\SET{expression}
	 		\INCR{expression}
	 		\DECR{expression}
	 * Expression :
	 	+
	 	-
	 	*
	 	/
	 	%
	 	EQ
	 	NEQ
	 	AND
	 	OR
	 	!
	 	>
	 	<
	 	NUMBER : chiffre ou nombre
	 	IDENTIFIER : idenfiant de variables
	 	{IDENTIFIER}{argument1,argument2} : appel d'une fonction avec arguments
	*/
	
	/*
		TODO :
		* Tester chaque programme pour le retour du if
	*/
	
	/**
	 * Notes :
	 * J'ai découvert que il est possible de mettre du code en plein milieu d'une gammaire (exemple : TOKEN TOKEN2 {code} TOKEN3)
	 * J'ai découvert que que le compteur de $ augmente de +1 quand il y a du code entre 2 tokens (ex : $17)
	 * La table des symboles est une liste chainée avec le premier élement qui est le dernier entrée
	 * Problème récursivité : factorielle(8) et fibonacci fonctione pas
	*/
%}
	
%union {
	int integer;
	symbol_type state;
	char id[64];
}
	
%token<integer> NUMBER
%type<state> expression
%token<id> IDENTIFIER

/* Mots clés d'instructions */
%token BEGIN_COMMAND END_COMMAND
%token IF_COMMAND ELSE_COMMAND FI_COMMAND
%token DOWHILE_COMMAND OD_COMMAND DOFORI_COMMAND
%token SET_COMMAND RETURN_COMMAND INCR_COMMAND DECR_COMMAND
	
/* Priorités des opérateurs */
%left AND OR
%left EQ NEQ '!'
%left '>' '<'
%left '+''-'
%left '*''/''%''^'
	
/* program = axiome */
%start program
%%
	program
		: program definition | definition
		;
	
	definition
		: function /* | declaration */
		;
	
	function
		: BEGIN_COMMAND '{' IDENTIFIER '}' {
			/**
			 * Nom du paquetage : IDENTIFIER
			 * Vérfication que le paquetage n'existe pas déja dans la pile 
			 de paquetages et enregistre le nom si ce n'est pas le cas
			*/
			const char *package_name = $3;
			struct stack_strings_entry *sse = NULL;
			sse = stack_strings_search_entry(stack_packages, package_name);
			if (sse == NULL) {
				stack_strings_push(stack_packages, package_name);
			} else {
				fail_with("Package %s is already exist\n", package_name);
			}
			printf("BEGIN PACKAGE : %s\n", $3);
		} '{' IDENTIFIER '}' {
			/**
			 * Nom de la fonction : IDENTIFIER
			 * Dans ce projet, le nom de la fonction est le même que celui
			 du fichier .tex
			*/
			function_name = $7;
			char filename_without_extension[FILENAME_MAX];
			strcpy(filename_without_extension, filename_parse);
			remove_extension(filename_without_extension);
			if (strcmp(filename_without_extension, function_name) != 0) {
				fprintf(stderr, "Dans ce projet, on suppose que le nom de "
				"la fonction correspond au nom du fichier !\n");
				fprintf(stderr, "Le programme %s doit "
				"avoir une fonction nommée %s\n", 
				filename_parse, function_name);
				exit(EXIT_FAILURE);
			}
			/**
			 * Vérification que la fonction n'existe pas déja dans la table
			 des symboles et l'enregistre si ce n'est pas le cas
			*/
			if (search_symbol_table(function_name) == NULL) {
				symbol_table_entry *symbol = new_symbol_table_entry(function_name);
				if (symbol == NULL) {
					fail_with("Symbol cannot be added to symbol table, "
						"NULL is return by new_symbol_table_entry\n");
				} else {
					symbol->class = FUNCTION;
					// Type de retour est toujours un entier
					symbol->desc[0] = INT_T;
				}
			} else {
				function_name = NULL;
				fail_with("Function %s is already exist (no override "
				"or redifinition)\n", function_name);
			}
			printf("NAME FUNCTION : %s\n", $7);
		} '{' parameter_list '}' {
			symbol_table_entry *symbol_function = search_symbol_table(function_name);
			if (symbol_function == NULL) {
				fail_with("Function name not found \n");
			} else if (symbol_function->nParams > 0) {
				// Déclare les variables de paramètre avant le label fonction
				fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
				fprintf(yyout, "; Déclaration des variables paramètres de la fonction\n");
				fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
				symbol_table_entry *ste = get_symbol_table();
				// le get_symbol_table() correspond au dernier paramètres entrée
				// donc dans le code assembleur ça va afficher du plus récent au plus ancien paramètre ajouté
				for (int i = 0; i < symbol_function->nParams; i++) {
					if (ste != NULL) {
						if (ste->class == LOCAL_VARIABLE || ste->class == GLOBAL_VARIABLE) {
							fprintf(yyout, "\tconst cx,jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, ste->name);
							fprintf(yyout, "\tjmp cx\n");			
							fprintf(yyout, ":%s%s\n", FORMAT_ASIPRO_LABEL_VAR, ste->name);
							switch (ste->desc[0]) {
								case INT_T : {
									fprintf(yyout, "@int %d\n", DEFAULT_ASIPRO_VAR_VALUE);
									break;
								}
								case STRING_T :
									/** 
										fprintf(yyout, "@string %s\n", "test");
										break; 
									*/
								default : {
									char msg_error[BUFFER_SIZE_MAX];
									sprintf(msg_error, "Le type de la variable %s n'est pas pris "
									"en charge pour ce programme, il n'est autorisé "
									"que le type entier\n", ste->name);
									yyerror(msg_error);
								}
							}
							fprintf(yyout, ":jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, ste->name);
						}
					}
					ste = ste->next;
				}
			}
			if (symbol_function->class != FUNCTION) {
				yyerror("Erreur le symbole représentant la fonction n'a pas la class FUNCTION\n");
			} else {
				/**
				 * Label de la fonction après la déclaration des variables
				 de paramètres
				*/
				fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;\n");
				fprintf(yyout, "; Fonction %s\n", function_name);
				fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;\n");
				fprintf(yyout, ":%s\n", function_name);
			}
			// Affectation d'une valeur au paramètre
			symbol_table_entry *ste = get_symbol_table();
			int address = 2;
			for (int i = 0; i < symbol_function->nParams; i++) {
				char lbl_paramname[BUFFER_SIZE_MAX];
				create_label(lbl_paramname, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, ste->name);
				/**
				 * Pour la récupération des arguments, il y a 2 méthodes :
				 1 - dépile l’adresse de retour, on dépile l’argument, 
				 et on remet l’adresse de retour sur la pile, 
				 2 - lire directement dans la pile, en dessous de son sommet
				 	Cette adresse d’instruction se trouvant au sommet de la pile 
				 	est donc désignée par sp, et l’argument se trouve à l’adresse 
				 	sp-2, 2 étant la taille d’un mot machine exprimé en cellules
				 	sp-2 puis sp-4 pour l'argument suivit, puis sp-6 ect
				 	C'est la 2ème méthode qui a été choisit
				*/
				fprintf(yyout, "; Calcul dans cx l'adresse de l'argument\n");
				fprintf(yyout, "\tcp cx,sp\n");
				fprintf(yyout, "\tconst bx,%d\n", address * (i+1));
				fprintf(yyout, "\tsub cx,bx\n");
				fprintf(yyout, "\tloadw ax,cx\n");
				fprintf(yyout, "; Affecte la valeur de cx dans la variable de l'argument\n");
				fprintf(yyout, "\tconst bx,%s\n", lbl_paramname);
				fprintf(yyout, "\tstorew ax,bx\n");
				ste = ste->next;
			}
		} statement_block {
			/**
			 * Production du code assembleur du bloc d'instruction(s)
			 dans la règle statement_block
			*/
			// Supprime les |$10=parameter_list| premiers élements de la table
			symbol_table_entry *symbol_function 
				= search_symbol_table(function_name);
			if (symbol_function == NULL) {
				fail_with("Function name not found "
				"to free parameters parsed\n");
			} else {
				symbol_table_entry *ste = get_symbol_table();
				printf("== Libération des symboles paramètres de la fonction ==\n");
				printf("Nombre de paramètre "
				"de la fonction %lu\n", symbol_function->nParams);
				for (int i = 0; i < symbol_function->nParams && ste != NULL; i++) {
					printf("Libération du paramètre "
					"de la fonction %s : %s\n", function_name, ste->name);
					free_first_symbol_table_entry();
					ste = get_symbol_table();
				}
			}
		} END_COMMAND '{' IDENTIFIER '}' {
			/**
			 * Vérification que le paquetage correspond au paquetage
			 déclaré le plus proche pour pas d'entralacement
			 $17 = car les accolades où il y a du code rajoute +1 à $
			*/
			const char *package_name = $18;
			const char *package_name_cmp = stack_strings_top(stack_packages);
			if (package_name_cmp == NULL) {
				fail_with("Package name on stack package not found\n", package_name);
			} else if (strncmp(package_name, package_name_cmp, 
				sizeof(char) * strlen(package_name)) != 0) {
				fail_with("Package %s is already exist\n", package_name);
			}
			// Libére le symbole du paquetage
			free_first_symbol_table_entry();
		}
		;
	parameter_list
		: parameter_list ',' parameter
		| parameter
		;
	
	parameter
		: %empty 
		| IDENTIFIER {
			/*
			 * Vérification que il n'existe pas un paramètre de même nom que
			 celui de $1=IDENTIFIER
			 * Normalement, cette vérification doit se faire au moment
			 où l'analyseur grammaticale bison est à la règle :
			 parameter_list ',' parameter {vérification...}
				Mais je n'ai pas trouvé comment faire car parameter = $3 indique
				une erreur (Ce n'est pas une unité lexicale) 
				et donc on peut pas récupèrer $3 = nom du paramètre
			*/
			const char *param_name = $1;
			if (search_symbol_table(param_name) != NULL) {
				fail_with("Parameter %s is already exist\n", param_name);
			} else {
				// Cherche la fonction
				symbol_table_entry *symbol_function 
					= search_symbol_table(function_name);
				if (symbol_function== NULL) {
					fail_with("Function name not found "
					"for parameters functions\n");
				} else {
					// Ajoute le paramètre à la table des symboles
					// Et augmente le compteur de nombre de paramètres de la fonction
					symbol_table_entry *symbol = new_symbol_table_entry(param_name);
					if (symbol == NULL) {
						fail_with("Symbol cannot be added to symbol table, "
							"NULL is return by new_symbol_table_entry\n");
					} else {
						// Paramètre en tant que variable locale
						symbol->class = LOCAL_VARIABLE;
						// De type int
						symbol->desc[0] = INT_T;
						// Numéro de portée (scope)
						symbol->add = get_num_scope();
					}
					/**
					 * Paramètres et variables ont tous le type INT 
					 car dans le sujet il est indiqué que les valeurs prises 
					 sont en entier
					*/
					symbol_function->desc[symbol_function->nParams] = INT_T;
					symbol_function->nParams++;
				}
			}
		}
		;
		
	// Pour ce langage, les déclarations sont considéres comme des instructions
	statement_block
		: /* declaration_list*/ {
			incr_num_scope();
			printf("Début du bloc : %u \n", get_num_scope());
		} statement_list {
			// supprime les |$1| = statement_list élements de la table
			// supprime les symboles qui ont le même numéro de portée que le block
			printf("Début de libération de symbole(s) pour le bloc %u\n", get_num_scope());
			for (symbol_table_entry *ste = get_symbol_table(); ste != NULL; ste = ste->next) {
				if (ste->add == get_num_scope()) {
					printf("Libération du symbole %s (numéro du bloc : %u)\n", ste->name, get_num_scope());
					free_first_symbol_table_entry();
				}
			}
			printf("Fin de libération de symbole(s) pour le bloc %u\n", get_num_scope());
			printf("Fin du bloc : %u \n", get_num_scope());
			decr_num_scope();
		}
		;
	
	/*---------------*/
	/* DECLARATION : */
	/*---------------*/
	/* Pour ce langage, les déclarations sont considéres 
		comme une instruction(assignment_statement) 
		car il n'y a pas de typage,
		donc je commente tout ce qui réfère une déclaration
		sinon il faut décommenter s'il y a du typage car
		une déclaration et une instruction d'affection sont différentes
		déclaration en C :
			TYPE IDENTIFIER = expression;
			TYPE IDENTIFIER; ect.
		instruction affection en C :
			IDENTIFIER = expression;
		déclaration en latex :
			SET '{' IDENTIFIER '}' '{' expression '}'
		instruction en latex :
			SET '{' IDENTIFIER '}' '{' expression '}'
		Donc j'ai choisi de dire que c'est une instruction d'affection
		(assignment_statement) pour éviter les conflits.
	*/
	/*
	declaration_list
		: declaration_list declaration
		| %empty
		;
	
	declaration :
		SET '{' IDENTIFIER '}' '{' expression '}' {
			
		}
	;
	*/
	
	/*-------------*/
	/* INSTRUCTION */
	/*-------------*/
	statement_list
		: statement_list statement 
		| statement
		;
		
	statement
		: selection_statement
		| iteration_statement
		| assignment_statement
		| jump_statement
		;
		
	selection_statement :
			/*
				* Type de cas - Exemples :
				* IF {expression} statement FI
				* IF {expression} statement ELSE statement FI
			*/
			IF_COMMAND '{' expression '}' begin_if statement_block end_if else fi
		;
		
	else :
		ELSE_COMMAND statement_block
		| %empty
		;
	
	begin_if : %empty {
		stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index] = stmts[SELECTION_IF].number++;
		char lbl_else[BUFFER_SIZE_MAX];
		create_label(lbl_else, BUFFER_SIZE_MAX, "%s:%u", "else", 
			stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index]);
		// Augmente l'index du if si d'autres if vont suivre
		stmts[SELECTION_IF].index++;
		/**
		 * dépile la valeur en sommet de pile et test si faux saute à else:1
		 * le test est vrai si la valeur de la condition est différente de 0
		*/
		fprintf(yyout, "\tpop ax\n");
		fprintf(yyout, "\tconst bx,0\n");
		fprintf(yyout, "\tconst cx,%s\n", lbl_else);
		fprintf(yyout, "\tcmp ax,bx\n");
		fprintf(yyout, "\tjmpc cx\n");
		
	}
	;
	
	end_if : %empty {
		// Retourne à l'index du if le plus proche
		stmts[SELECTION_IF].index--;
		char lbl_endif[BUFFER_SIZE_MAX];
		create_label(lbl_endif, BUFFER_SIZE_MAX, "%s:%u", "endif", 
			stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index]);
		char lbl_else[BUFFER_SIZE_MAX];
		create_label(lbl_else, BUFFER_SIZE_MAX, "%s:%u", "else", 
			stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index]);
		// saute endif:1
		fprintf(yyout, "\tconst ax,%s\n", lbl_endif);
		fprintf(yyout, "\tjmp ax\n");
		// étiquette else:1 si le if est faux
		fprintf(yyout, ":%s\n", lbl_else);
		// Augmente l'index du if si un else va suivre
		stmts[SELECTION_IF].index++;
	}
	;
	
	fi : FI_COMMAND {
		// Retourne à l'index du if le plus proche, pour la fin du if
		stmts[SELECTION_IF].index--;
		// fin de la condition
		char lbl_endif[BUFFER_SIZE_MAX];
		create_label(lbl_endif, BUFFER_SIZE_MAX, "%s:%u", "endif", 
			stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index]);
		fprintf(yyout, ":%s\n", lbl_endif);
		printf("Avant Décr : IF[%lu] = %lu\n", stmts[SELECTION_IF].index, stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index]);
		//stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index--] = 0;
		// Remonte dans la pile, pour dire que c'est une dépilation
		printf("Après Décr : IF[%lu] = %lu\n", stmts[SELECTION_IF].index, stmts[SELECTION_IF].stack[stmts[SELECTION_IF].index]);
	} 
	;
	
	iteration_statement
		: DOWHILE_COMMAND { 
			stmts[ITERATION_WHILE].stack[stmts[ITERATION_WHILE].index] 
			= stmts[ITERATION_WHILE].number++;
			char lbl_beginwhile[BUFFER_SIZE_MAX];
			create_label(lbl_beginwhile, BUFFER_SIZE_MAX, "%s:%u", "beginwhile", 
				stmts[ITERATION_WHILE].stack[stmts[ITERATION_WHILE].index]);
			stmts[ITERATION_WHILE].index++;
			/** 
			 * Création de l'étiquette de la boucle tant que 
			 * pour revenir à cette étiquette si la condition est fausse
			*/
			fprintf(yyout, ":%s\n", lbl_beginwhile);
			
			} '{' expression '}' {
				/** 
				 * Dépile la condition et test la valeur du sommet de pile 
				 * si test faux saute à à l'étiquette :endwhile pour pas éxécuter la boucle tant que
				 * si test vrai (si la valeur de la condition est différente de 0) éxécute la boucle tant que
				*/
				stmts[ITERATION_WHILE].index--;
				char lbl_endwhile[BUFFER_SIZE_MAX];
				create_label(lbl_endwhile, BUFFER_SIZE_MAX, "%s:%u", "endwhile",
					stmts[ITERATION_WHILE].stack[stmts[ITERATION_WHILE].index]);
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tconst bx,0\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_endwhile);
				fprintf(yyout, "\tcmp ax,bx\n");
				fprintf(yyout, "\tjmpc cx\n");
				// Ré-incrémentation pour le end_while
				stmts[ITERATION_WHILE].index++;
			} { fprintf(yyout, "; bloc d'instructions de la boucle while\n"); }  statement_block end_while
		| DOFORI_COMMAND '{' IDENTIFIER '}' {
			
			// Vérification que l'identifiant n'existe pas déja
			const char *varname = $3;
			if (search_symbol_table(varname)) {
				char msg_error[BUFFER_SIZE_MAX];
				sprintf(msg_error, "Boucle pour : Erreur le symbole %s existe déja, "
				"utiliser un nouveau symbole\n", varname);
				yyerror(msg_error);
			} else {
				symbol_table_entry *symbol = new_symbol_table_entry(varname);
				if (symbol == NULL) {
					fail_with("For loop : Symbol cannot be added to symbol table, "
							"NULL is return by new_symbol_table_entry\n");
				} else {
					// Création de la variable du for en tant que variable locale
					symbol->class = LOCAL_VARIABLE;
					symbol->desc[0] = INT_T;
					symbol->add = get_num_scope();
					/**
					 * Astuce :
					 Lorsqu'une nouvelle variable est rencontrée, elle est crée et afficher directement
					 Or cela causer d'erreur dans l'éxécution 
					 car une boucle imbriqué peut repasser par ce code qui recréer la variable
					 * Saute à jumpvar:nom_variable : ajout d'un saut pour ne pas recréer la variable
					*/
					fprintf(yyout, "\tconst cx,jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, symbol->name);
					fprintf(yyout, "\tjmp cx\n");
					// Déclare la variable
					fprintf(yyout, ":%s%s\n", FORMAT_ASIPRO_LABEL_VAR, symbol->name);
					fprintf(yyout, "@int %d\n", DEFAULT_ASIPRO_VAR_VALUE);
					fprintf(yyout, ":jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, symbol->name);
					
				}
			}
		} '{' expression '}' {
			
			char lbl_var[BUFFER_SIZE_MAX];
			create_label(lbl_var, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, $3);
			fprintf(yyout, "\tpop ax\n");
			fprintf(yyout, "\tconst bx,%s\n", lbl_var);
			fprintf(yyout, "\tstorew ax,bx\n");
			
			// Début de la boucle for
			stmts[ITERATION_FOR].stack[stmts[ITERATION_FOR].index] 
				= stmts[ITERATION_FOR].number++;
			char lbl_beginfor[BUFFER_SIZE_MAX];
			create_label(lbl_beginfor, BUFFER_SIZE_MAX, "%s:%u", "beginfor", 
				stmts[ITERATION_FOR].stack[stmts[ITERATION_FOR].index]);
			// :beginfor:0
			fprintf(yyout, ":%s\n", lbl_beginfor);
				
		} '{' expression '}' {
				
			// Comparaison si variable < expression
			// Si vrai met 1, 0 sinon en sommet de pile
			char lbl_true[BUFFER_SIZE_MAX];
			char lbl_endtrue[BUFFER_SIZE_MAX];
			unsigned int ln = new_label_number();
			create_label(lbl_true, BUFFER_SIZE_MAX, "%s:%s:%u", "lt", "true", ln);
			create_label(lbl_endtrue, BUFFER_SIZE_MAX, "%s:%s:%u", "lt", "endtrue", ln);
			char lbl_var[BUFFER_SIZE_MAX];
			create_label(lbl_var, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, $3);
			fprintf(yyout, "\tconst cx,%s\n", lbl_var);
			// Charge la valeur de la variable locale du for dans le registre ax
			fprintf(yyout, "\tloadw ax,cx\n");
			// Dépile la valeur de l'expression rencontré précédemment dans le registre bx
			fprintf(yyout, "\tpop bx\n");
			fprintf(yyout, "\tconst cx,%s\n", lbl_true);
			fprintf(yyout, "\tsless ax,bx\n");
			fprintf(yyout, "\tjmpc cx\n");
			fprintf(yyout, "\tconst ax,0\n");
			fprintf(yyout, "\tpush ax\n");
			fprintf(yyout, "\tconst cx,%s\n", lbl_endtrue);
			fprintf(yyout, "\tjmp cx\n");
			fprintf(yyout, ":%s\n", lbl_true);
			fprintf(yyout, "\tconst ax,1\n");
			fprintf(yyout, "\tpush ax\n");
			fprintf(yyout, ":%s\n", lbl_endtrue);
			
			// Fais la comparaison si doit retourner au début du for
			// Dépile la valeur mis sur la pile lors de la comparaison de variable < NUMBER
			char lbl_endfor[BUFFER_SIZE_MAX];
			create_label(lbl_endfor, BUFFER_SIZE_MAX, "%s:%u", "endfor",
				stmts[ITERATION_FOR].stack[stmts[ITERATION_FOR].index]);
			// Augmente l'index dans le cas d'autres boucle for imbriquées
			stmts[ITERATION_FOR].index++;
			fprintf(yyout, "\tpop ax\n");
			fprintf(yyout, "\tconst bx,0\n");
			fprintf(yyout, "\tconst cx,%s\n", lbl_endfor);
			fprintf(yyout, "\tcmp ax,bx\n");
			fprintf(yyout, "\tjmpc cx\n");
			
		} statement_block OD_COMMAND {
			// Incrémente le compteur
			char lbl_varname[BUFFER_SIZE_MAX];
			create_label(lbl_varname, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, $3);
			fprintf(yyout, "\tconst bx,%s\n", lbl_varname);
			fprintf(yyout, "\tloadw ax,bx\n");
			fprintf(yyout, "\tconst bx,1\n");
			fprintf(yyout, "\tadd ax,bx\n");
			fprintf(yyout, "\tconst bx,%s\n", lbl_varname);
			fprintf(yyout, "\tstorew ax,bx\n");
			stmts[ITERATION_FOR].index--;
			char lbl_beginfor[BUFFER_SIZE_MAX];
			create_label(lbl_beginfor, BUFFER_SIZE_MAX, "%s:%u", "beginfor", 
				stmts[ITERATION_FOR].stack[stmts[ITERATION_FOR].index]);
			char lbl_endfor[BUFFER_SIZE_MAX];
			create_label(lbl_endfor, BUFFER_SIZE_MAX, "%s:%u", "endfor",
				stmts[ITERATION_FOR].stack[stmts[ITERATION_FOR].index]);
			// Retourne au début de la boucle for
			fprintf(yyout, "\tconst cx,%s\n", lbl_beginfor);
			fprintf(yyout, "\tjmp cx\n");
			// Si la condition était fausse, donc sort du for, fin de la boucle for
			fprintf(yyout, ":%s\n", lbl_endfor);
			// Libére la variable locale du for
			free_first_symbol_table_entry();
		}
		;
		
	end_while : OD_COMMAND {
		stmts[ITERATION_WHILE].index--;
		char lbl_beginwhile[BUFFER_SIZE_MAX];
		create_label(lbl_beginwhile, BUFFER_SIZE_MAX, "%s:%u", "beginwhile", 
			stmts[ITERATION_WHILE].stack[stmts[ITERATION_WHILE].index]);
		char lbl_endwhile[BUFFER_SIZE_MAX];
		create_label(lbl_endwhile, BUFFER_SIZE_MAX, "%s:%u", "endwhile",
			stmts[ITERATION_WHILE].stack[stmts[ITERATION_WHILE].index]);
		// Retourne au début de la boucle while
		fprintf(yyout, "\tconst cx,%s\n", lbl_beginwhile);
		fprintf(yyout, "\tjmp cx\n");
		// Si la condition était fausse, donc sort du while
		// fin de la boucle while
		fprintf(yyout, ":%s\n", lbl_endwhile);
	}
	;
	
	assignment_statement
		: SET_COMMAND '{' IDENTIFIER '}' '{' expression '}' {
			char varname[MAX_VARNAME];
			snprintf(varname, sizeof(varname), "%s", $3);
			char lbl_varname[BUFFER_SIZE_MAX];
			create_label(lbl_varname, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, varname);
			if (search_symbol_table(varname) == NULL) {
				symbol_table_entry *symbol = new_symbol_table_entry(varname);
				if (symbol == NULL) {
					fail_with("Symbol cannot be added to symbol table, "
						"NULL is return by new_symbol_table_entry\n");
				} else {
					/**
					 * Affecte les informations de la variable locale
					 à la fonction
					*/
					symbol->class = LOCAL_VARIABLE;
					symbol->desc[0] = INT_T;
					symbol->add = get_num_scope();
					/**
					 * Augmente le compteur de nombre de variables 
					 de la fonction
					*/ 
					symbol_table_entry *function = search_symbol_table(function_name);
					if (function == NULL) {
						fail_with("Function name not found "
						"for local variable\n");
					} else {
						function->nLocalVariables++;
					}
					fprintf(yyout, "\tconst cx,jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, symbol->name);
					fprintf(yyout, "\tjmp cx\n");
					// Déclare la variable
					fprintf(yyout, ":%s%s\n", FORMAT_ASIPRO_LABEL_VAR, symbol->name);
					fprintf(yyout, "@int %d\n", DEFAULT_ASIPRO_VAR_VALUE);
					fprintf(yyout, ":jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, symbol->name);
					/**
					 * Production du code asipro(assembleur) 
					 de la variable qui reçoit la valeur d'une expression
					*/
					fprintf(yyout, "; Affectation(\\SET) de la variable %s\n", varname);
					fprintf(yyout, "\tpop ax\n");
					fprintf(yyout, "\tconst bx,%s\n", lbl_varname);
					fprintf(yyout, "\tstorew ax,bx\n");
				}
			} else {
				/* Pas besoin car une variable est pas typé */
				/* fail_with("Erreur, la variable %s existe \
					déja dans la table des symboles !\n", varname); */
				// Récupère la variable enregistré dans la table des symboles
				symbol_table_entry *tmp_symbol = search_symbol_table(varname);
				if (tmp_symbol == NULL) {
					fail_with("[SET_COMMAND] symbol_table_entry not found for %s\n", varname);
				} else {
					fprintf(yyout, "; Affectation(\\SET) de la variable %s\n", varname);
					fprintf(yyout, "\tpop ax\n");
					fprintf(yyout, "\tconst bx,%s\n", lbl_varname);
					fprintf(yyout, "\tstorew ax,bx\n");
				}
			}
		} | INCR_COMMAND '{' IDENTIFIER {
				/** 
				 * L'incrémentation ne se fait que sur les variables est pas sur une expression
				 * J'ai fait une erreur en supposant que INCR_COMMAND '{' expression '}'
				*/
				// Vérification que l'identifiant existe en table des symboles
				const char *varname = $3;
				if (search_symbol_table(varname) == NULL) {
					fail_with("[INCR_COMMAND] symbol_table_entry not found for %s\n", varname);
				} else {
					char lbl_var[BUFFER_SIZE_MAX];
					create_label(lbl_var, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, varname);
					fprintf(yyout, "\tconst bx,%s\n", lbl_var);
					fprintf(yyout, "\tloadw ax,bx\n");
				}
			
			} '}' {
			char lbl_varname[BUFFER_SIZE_MAX];
			create_label(lbl_varname, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, $3);
			/**
			 * Après que l'identifiant est correct, généré le code asipro pour l'incrémentation
			 * Ajoute +1 à ax qui contient le résultat de la variable
			*/
			fprintf(yyout, "\tconst bx,1\n");
			fprintf(yyout, "\tadd ax,bx\n");
			fprintf(yyout, "\tconst bx,%s\n", lbl_varname);
			fprintf(yyout, "\tstorew ax,bx\n");
		} | DECR_COMMAND '{' IDENTIFIER {
			const char *varname = $3;
			if (search_symbol_table(varname) == NULL) {
				fail_with("[DECR_COMMAND] symbol_table_entry not found for %s\n", varname);
			} else {
				char lbl_var[BUFFER_SIZE_MAX];
				create_label(lbl_var, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, varname);
				fprintf(yyout, "\tconst bx,%s\n", lbl_var);
				fprintf(yyout, "\tloadw ax,bx\n");
			}
		} '}' {
			char lbl_varname[BUFFER_SIZE_MAX];
			create_label(lbl_varname, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, $3);
			// Ajoute -1 à ax qui contient le résultat de la variable
			fprintf(yyout, "\tconst bx,1\n");
			fprintf(yyout, "\tsub ax,bx\n");
			fprintf(yyout, "\tconst bx,%s\n", lbl_varname);
			fprintf(yyout, "\tstorew ax,bx\n");
		}
		;
		
	jump_statement
		: RETURN_COMMAND '{' expression '}' {
			/**
			 * La valeur se trouvant en sommet de pile
			 * Dépile et la met dans ax par convention
			 * Au retour de la fonction, le résultat est dans le registre ax
			*/
			fprintf(yyout, "\tpop ax\n");
			fprintf(yyout, "\tret\n");
		}
		;
	
	/*------------*/
	/* EXPRESSION */
	/*------------*/
	expression :
		'(' expression ')' {
			/* on fait rien sur la pile sur les parenthèses, on remonte juste l'expressionession = $2 */
			$$ = $2;
		} | expression '+' expression {
			/* $1 = expression, $2 = '+', $3 = expression */
			if (COMPATIBLE_TYPES($1, $3)) {
				// dépile la pile dont la valeur est mise dans le registre ax
				fprintf(yyout, "\tpop ax\n");
				// dépile la pile dont la valeur est mise dans bx
				fprintf(yyout, "\tpop bx\n");
				// effectue le plus de ax+bx et met le résultat dans ax
				fprintf(yyout, "\tadd ax,bx\n");
				// pousse ax sur la pile (au sommet)
				fprintf(yyout, "\tpush ax\n");
				$$ = INT_T_LVALUE;
			} else {
				yyerror("[Erreur] '+' de typage");
				$$ = ERROR_T;
			}
		} | expression '-' expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tsub ax,bx\n");
				fprintf(yyout, "\tpush ax\n");
				$$ = INT_T_LVALUE;
			} else {
				yyerror("[Erreur] '*' de typage");
				$$ = ERROR_T;
			}
		} | expression '*' expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tmul ax,bx\n");
				fprintf(yyout, "\tpush ax\n");
				$$ = INT_T_LVALUE;
			} else {
				yyerror("[Erreur] '*' de typage");
				$$ = ERROR_T;
			}
		} | expression '/' expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				char lbl_errordiv[BUFFER_SIZE_MAX];
				char lbl_end_div[BUFFER_SIZE_MAX];
				unsigned int ln = new_label_number();
				create_label(lbl_errordiv, BUFFER_SIZE_MAX, "%s:%s:%u", "err", "div0", ln);
				create_label(lbl_end_div, BUFFER_SIZE_MAX, "%s:%s:%u", "fin", "div", ln);
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_errordiv);
				fprintf(yyout, "\tdiv ax,bx\n");
				fprintf(yyout, "\tjmpe cx\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tconst ax,%s\n", lbl_end_div);
				fprintf(yyout, "\tjmp ax\n");
				fprintf(yyout, ":%s\n", lbl_errordiv);
				fprintf(yyout, "\tconst ax,%s\n", lbl_string_errordiv);
				fprintf(yyout, "\tcallprintfs ax\n");
				fprintf(yyout, "\tend\n");
				// si pas d'erreur ça sort sur ce label qui fait rien
				fprintf(yyout, ":%s\n", lbl_end_div);
				$$ = INT_T_LVALUE;
			} else {
				yyerror("[Erreur] '/' de typage");
				$$ = ERROR_T;
			}
		} | expression '%' expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				char lbl_errordiv[BUFFER_SIZE_MAX];
				char lbl_end_div[BUFFER_SIZE_MAX];
				unsigned int ln = new_label_number();
				create_label(lbl_errordiv, BUFFER_SIZE_MAX, "%s:%s:%u", "err", "div0", ln);
				create_label(lbl_end_div, BUFFER_SIZE_MAX, "%s:%s:%u", "fin", "div", ln);
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tcp dx,ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_errordiv);
				fprintf(yyout, "\tdiv ax,bx\n");
				fprintf(yyout, "\tjmpe cx\n");
				// copie de dx dans cx qui contient ax pour l'utiliser plustard
				fprintf(yyout, "\tcp cx,dx\n");
				fprintf(yyout, "\tcp dx,bx\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tconst ax,%s\n", lbl_end_div);
				fprintf(yyout, "\tjmp ax\n");
				fprintf(yyout, ":%s\n", lbl_errordiv);
				fprintf(yyout, "\tconst ax,%s\n", lbl_string_errordiv);
				fprintf(yyout, "\tcallprintfs ax\n");
				fprintf(yyout, "\tend\n");
				fprintf(yyout, ":%s\n", lbl_end_div);
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tmul ax,dx\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tsub cx,ax\n");
				fprintf(yyout, "\tpush cx\n");
				$$ = INT_T_LVALUE;
			} else {
				yyerror("[Erreur] '%%' de typage");
				$$ = ERROR_T;
			}
		} | expression EQ expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				char lbl_eqtrue[BUFFER_SIZE_MAX];
				char lbl_endeqtrue[BUFFER_SIZE_MAX];
				unsigned int ln = new_label_number();
				create_label(lbl_eqtrue, BUFFER_SIZE_MAX, 
					"%s:%s:%u", "eq", "true", ln);
				create_label(lbl_endeqtrue, BUFFER_SIZE_MAX, 
					"%s:%s:%u", "endeq", "true", ln);
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_eqtrue);
				fprintf(yyout, "\tcmp ax,bx\n");
				fprintf(yyout, "\tjmpc cx\n");
				fprintf(yyout, "\tconst ax,0\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_endeqtrue);
				fprintf(yyout, "\tjmp cx\n");
				fprintf(yyout, ":%s\n", lbl_eqtrue);
				fprintf(yyout, "\tconst ax,1\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, ":%s\n", lbl_endeqtrue);
				$$ = INT_T_LVALUE;
			} else {
				yyerror("[Erreur] '==' de typage");
				$$ = ERROR_T;
			}
		} | expression NEQ expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				char lbl_neqfalse[BUFFER_SIZE_MAX];
				char lbl_endneqfalse[BUFFER_SIZE_MAX];
				unsigned int ln = new_label_number();
				create_label(lbl_neqfalse, BUFFER_SIZE_MAX, 
					"%s:%s:%u", "neq", "false", ln);
				create_label(lbl_endneqfalse, BUFFER_SIZE_MAX, 
					"%s:%s:%u", "endneq", "false", ln);
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_neqfalse);
				fprintf(yyout, "\tcmp ax,bx\n");
				fprintf(yyout, "\tjmpc cx\n");
				fprintf(yyout, "\tconst ax,1\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_endneqfalse);
				fprintf(yyout, "\tjmp cx\n");
				fprintf(yyout, ":%s\n", lbl_neqfalse);
				fprintf(yyout, "\tconst ax,0\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, ":%s\n", lbl_endneqfalse);
				$$ = INT_T_LVALUE;
			} else {
				yyerror("[Erreur] '!=' de typage");
				$$ = ERROR_T;
			}
		} | expression AND expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tand ax,bx\n");
				fprintf(yyout, "\tpush ax\n");
				$$ = INT_T_LVALUE;
			} else {
				$$ = ERROR_T;
			}/*else if ($1 != T_BOOLEAN) {
				if ($1 == INT_T) {
					$$ = ERROR_T;
				} else {
					$$ = $1;
				}
			} else {
				if ($3 == INT_T) {
					$$ = ERROR_T;
				} else {
					$$ = $3;
				}
			}*/
		} | expression OR expression {
			if (COMPATIBLE_TYPES($1, $3)) {
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tor ax,bx\n");
				fprintf(yyout, "\tpush ax\n");
				$$ = INT_T_LVALUE;
			} else {
				$$ = ERROR_T;
			}/*else if ($1 != T_LBOOLEAN) {
				if ($1 == INT_T_LVALUE) {
					$$ = ERROR_T;
				} else {
					$$ = $1; // = INT_T_LVALUE
				}
			} else {
				if ($3 == INT_T_LVALUE) {
					$$ = ERROR_T;
				} else {
					$$ = $3; // = INT_T_LVALUE
				}
			}*/
		} | '!' expression {
			// INT_T_LVALUE : valeur littéral (0,1,2)
			// INT_T : variable
			if ($2 == INT_T_LVALUE || $2 == INT_T) {
				/*fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tnot ax\n");
				fprintf(yyout, "\tpush ax\n");*/
				char lbl_nottrue[BUFFER_SIZE_MAX];
				char lbl_endnottrue[BUFFER_SIZE_MAX];
				unsigned int ln = new_label_number();
				create_label(lbl_nottrue, BUFFER_SIZE_MAX, 
					"%s:%s:%u", "not", "true", ln);
				create_label(lbl_endnottrue, BUFFER_SIZE_MAX, 
					"%s:%s:%u", "endnot", "true", ln);
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tconst bx,0\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_nottrue);
				fprintf(yyout, "\tcmp ax,bx\n");
				fprintf(yyout, "\tjmpc cx\n");
				fprintf(yyout, "\tconst ax,0\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_endnottrue);
				fprintf(yyout, "\tjmp cx\n");
				fprintf(yyout, ":%s\n", lbl_nottrue);
				fprintf(yyout, "\tconst ax,1\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, ":%s\n", lbl_endnottrue);
				$$ = INT_T_LVALUE;
			} else {
				$$ = ERROR_T;
			}
		} | expression '>' expression {
				char lbl_true[BUFFER_SIZE_MAX];
				char lbl_endtrue[BUFFER_SIZE_MAX];
				unsigned int ln = new_label_number();
				create_label(lbl_true, BUFFER_SIZE_MAX, "%s:%s:%u", "gt", "true", ln);
				create_label(lbl_endtrue, BUFFER_SIZE_MAX, "%s:%s:%u", "gt", "endtrue", ln);
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_true);
				fprintf(yyout, "\tsless bx,ax\n");
				fprintf(yyout, "\tjmpc cx\n");
				fprintf(yyout, "\tconst ax,0\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_endtrue);
				fprintf(yyout, "\tjmp cx\n");
				fprintf(yyout, ":%s\n", lbl_true);
				fprintf(yyout, "\tconst ax,1\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, ":%s\n", lbl_endtrue);
				$$ = INT_T_LVALUE;
		} | expression '<' expression {
				char lbl_true[BUFFER_SIZE_MAX];
				char lbl_endtrue[BUFFER_SIZE_MAX];
				unsigned int ln = new_label_number();
				create_label(lbl_true, BUFFER_SIZE_MAX, "%s:%s:%u", "lt", "true", ln);
				create_label(lbl_endtrue, BUFFER_SIZE_MAX, "%s:%s:%u", "lt", "endtrue", ln);
				fprintf(yyout, "\tpop bx\n");
				fprintf(yyout, "\tpop ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_true);
				fprintf(yyout, "\tsless ax,bx\n");
				fprintf(yyout, "\tjmpc cx\n");
				fprintf(yyout, "\tconst ax,0\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, "\tconst cx,%s\n", lbl_endtrue);
				fprintf(yyout, "\tjmp cx\n");
				fprintf(yyout, ":%s\n", lbl_true);
				fprintf(yyout, "\tconst ax,1\n");
				fprintf(yyout, "\tpush ax\n");
				fprintf(yyout, ":%s\n", lbl_endtrue);
				$$ = INT_T_LVALUE;
		} | NUMBER {
			fprintf(yyout, "\tconst ax,%d\n", $1);
			fprintf(yyout, "\tpush ax\n");
			$$ = INT_T_LVALUE;
		} | IDENTIFIER {
			// Variable
			symbol_table_entry *symbol = NULL;
			if ((symbol = search_symbol_table($1)) == NULL) {
				char msg_error[BUFFER_SIZE_MAX];
				sprintf(msg_error, "Erreur le symbole %s est inconnu, "
				"vérifier qu'il existe ou bien sa portée est incorrecte\n", $1);
				yyerror(msg_error);
				$$ = ERROR_T;
			} else {
				symbol_type type = INT_T;
				symbol->desc[0] = type;
				char lbl_var[BUFFER_SIZE_MAX];
				create_label(lbl_var, BUFFER_SIZE_MAX, "%s%s", FORMAT_ASIPRO_LABEL_VAR, $1);
				fprintf(yyout, "\tconst bx,%s\n", lbl_var);
				fprintf(yyout, "\tloadw ax,bx\n");
				fprintf(yyout, "\tpush ax\n");
				$$ = type;
			}
		} | '{' IDENTIFIER '}' '{' argument_expression_list '}' {
			// Appel de fonction
			/**
			 * Vérification que l'identifiant est le nom de la fonction 
			*/
			symbol_table_entry *ste = search_symbol_table($2);
			if (ste == NULL || ste->class != FUNCTION) {
				char msg_error[BUFFER_SIZE_MAX];
				sprintf(msg_error, "Le nom de la fonction %s est incorrect "
				"car l'appel de cette fonction ne porte pas le nom %s\n", $2, function_name);
				yyerror(msg_error);
			}
			
			// Récupére le symbol fonction
			symbol_table_entry *ste_function = search_symbol_table(function_name);
			if (ste_function == NULL) {
				fail_with("Function name not found to call function\n");
			}
			/**
			 * Vérification que le nombre de paramètres correpond 
			 au nombre attendues par la fonction
			*/
			if (get_count_args() != ste_function->nParams) {
				char msg_error[BUFFER_SIZE_MAX];
				char plural = ste_function->nParams > 1 ? 's' : '\0';
				sprintf(msg_error, "La fonction %s attend %lu argument%c"
				", car l'appel de cette fonction ne porte pas le nom %s\n", 
				$2, ste_function->nParams, plural, function_name);
				yyerror(msg_error);
			}
			// Réinitialise le nombre d'arguments
			reset_count_args();
			// La fonction retourne un entier
			$$ = INT_T_LVALUE;
			fprintf(yyout, "; Appel de la fonction\n");
			fprintf(yyout, "\tconst bx,%s\n", function_name);
			fprintf(yyout, "\tcall bx\n");
			fprintf(yyout, "; Dépile les arguments de la fonction\n");
			for (int i = 0; i < ste_function->nParams; i++) {
				fprintf(yyout, "\tpop bx\n");
			}
			// Comme la valeur se trouve dans ax et que il y a un nouvelle appel de fonction
			// empile la valeur
			fprintf(yyout, "; Empile la valeur pour nouvelle appel de fonction\n");
			fprintf(yyout, "\tpush ax\n");
		}
	;
	
	argument_expression_list
		: argument_expression_list ',' assignment_expression
		| assignment_expression
		;
	assignment_expression
		: %empty
		| expression {
			incr_count_args();
		}
		;
%%
	
void yyerror(const char *msg_error) {
	fprintf(stderr, "%s\n", msg_error);
	if (filename_out == NULL) {
		fprintf(stderr, "Erreur lors de la récupération du nom de "
		"fichier pour supprimer le fichier ASIPRO en cas d'erreur indiqué "
		"par bison\n");
		exit(EXIT_FAILURE);
	}
	if (remove(filename_out) == -1) {
		fprintf(stderr, "Erreur lors de la suppression du fichier "
		"%s car une erreur bison a été rencontré\n", filename_out);
	} else {
		fprintf(stdout, "Le fichier %s n'a pas été généré "
		"car une erreur est survenue dans l'analyse du %s\n", 
		filename_out, filename_parse);
	}
	exit(EXIT_FAILURE);
}
	
	
int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "Usage : %s %s\n", argv[0], "<file.tex>");
		exit(EXIT_FAILURE);
	}
	
	filename_parse = basename(argv[1]);
	if (filename_parse == NULL) {
		fprintf(stderr, "Erreur lors de la récupération du nom de fichier "\
		"à analyser\n");
		exit(EXIT_FAILURE);
	}
	
	printf("==================================================================\n");
	printf("== Lancement du programme %s\n", argv[0]);
	printf("== Analyse du fichier %s\n", filename_parse);
	printf("==================================================================\n");
	
	// Ouverture du fichier à analyser
	yyin = fopen(argv[1], "r");
	if (yyin == NULL) {
		perror("fopen");
		exit(EXIT_FAILURE);
	}
	
	// Ouverture du fichier d'assembleur pour y écrire le code assembleur
	const char *filename_out_tmp = basename(argv[1]);
	snprintf(filename_out, sizeof(filename_out), "%s", filename_out_tmp);
	// Remplace le .tex par .asm
	char *result = replace_word(filename_out, ".tex", ".asm");
	snprintf(filename_out, sizeof(filename_out), "%s", result);
	yyout = fopen(filename_out, "w");
	if (yyout == NULL) {
		perror("fopen");
		exit(EXIT_FAILURE);
	}
	
	/**
	 * Initialisation de la pile des noms de paquetages 
	 * (même si il doit y en avoir que un seul)
	*/
	stack_packages = new_stack_strings();
	
	// Déclarations des constantes (strings, int) qui peuvent être utiliser
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(yyout, "; Début de la zone de stockage des constantes\n");
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	
	// String pour division par zéro
	create_label(lbl_string_errordiv, BUFFER_SIZE_MAX, "%s:%s:%u", 
		"s_err", "div0", new_label_number());
	fprintf(yyout, ":%s\n", lbl_string_errordiv);
	fprintf(yyout, "@string \"Erreur de division par 0\\n\"\n");
	
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(yyout, "; Fin de la zone de stockage des constantes\n");
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	
	// Analyse grammaticale
	printf("== Affichage d'informations de la table des symboles\n");
	yyparse();
	
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(yyout, "; Début de déclaration des variables de la fonction\n");
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	int default_value = DEFAULT_ASIPRO_VAR_VALUE;
	// L'initialisation des variables locales à la fonction à zéro
	for (symbol_table_entry *ste = get_symbol_table(); ste != NULL; ste = ste->next) {
		/**
		 * Ajout de GLOBAL_VARIABLE dans la condition même si y'en a pas besoin 
		 car ce ne sont que des variables locales dans la fonction
		*/
		if (ste->class == LOCAL_VARIABLE || ste->class == GLOBAL_VARIABLE) {
			fprintf(yyout, "\tconst cx,jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, ste->name);
			fprintf(yyout, "\tjmp cx\n");
			fprintf(yyout, ":%s%s\n", FORMAT_ASIPRO_LABEL_VAR, ste->name);
			switch (ste->desc[0]) {
				case INT_T : {
					fprintf(yyout, "@int %d\n", default_value);
					break;
				}
				case STRING_T :
					/** 
						fprintf(yyout, "@string %s\n", "test");
						break; 
					*/
				default : {
					fprintf(stderr, "Le type de la variable %s n'est pas pris "
					"en charge pour ce programme, il n'est autorisé "
					"que le type entier\n", ste->name);
					exit(EXIT_FAILURE);
				}
			}
			fprintf(yyout, ":jump:%s%s\n", FORMAT_ASIPRO_LABEL_VAR, ste->name);
		}
	}
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(yyout, "; Fin de déclaration des variables de la fonction\n");
	fprintf(yyout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	
	// Fermeture du fichier d'écriture en assembleur
	if (fclose(yyout) == EOF) {
		perror("fclose");
	}
	
	// Fermeture du fichier à analyser
	if (fclose(yyin) == EOF) {
		perror("fclose");
	}
	
	printf("Toutes les ressources de la table des symboles "
	"alloués sont libérées ? %d\n", get_symbol_table() == NULL);
	// Libération des ressources alloués de la table des symboles
	for (symbol_table_entry *ste = get_symbol_table(); ste != NULL; ste = ste->next) {
		free_first_symbol_table_entry();
	}
	
	printf("================================================\n");
	printf("== Analyse du fichier %s terminée\n", filename_parse);
	printf("== Fichier assembleur ASIPRO généré : %s\n", filename_out);
	printf("== Il maintenant utiliser le program run pour l'éxécuter\n");
	printf("== Fin du programme %s\n", argv[0]);
	printf("================================================\n");
	
	return EXIT_SUCCESS;
}
