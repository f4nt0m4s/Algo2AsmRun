#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#define COMMAND_NAME "\\SIPRO"
#define ASM_EXTENSION "asm"
#define BUFFER_MAX 1024
#define ASM_MAIN_FUNCTION "debut"
#define PROGRAM_ALGO2ASIPRO "algo2asm"

void usage_cmd_and_exit(void);

const char *program_name = NULL;
const char *function_name = NULL;

int main(int argc, char *argv[]) {
	program_name = argv[0];
	if (argc != 2) {
		usage_cmd_and_exit();
	}
	
	// Le shell supprime les guillemets donc pas besoin de vérifier
	/*
	printf("%c - %c\n", argv[1][0], argv[1][strlen(argv[1])-1]);
	if (argv[1][0] != '\'' || argv[1][strlen(argv[1])-1] != '\'' ) {
		fprintf(stderr, "La commande doit être commencé par ' et se terminé par ' \n");
		usage_cmd_and_exit();
	}
	*/
	
	const char *delim = "{}";
	char *token = strtok(argv[1], delim);
	if (token == NULL || strncmp(argv[1], COMMAND_NAME, sizeof(char) * strlen(argv[1])) != 0) {
		fprintf(stderr, "Le nom de la commande %s ne correspond à %s\n", argv[1], COMMAND_NAME);
		usage_cmd_and_exit();
	}
	
	token = strtok(NULL, delim);
	if (token == NULL) {
		fprintf(stderr, "Le nom de la fonction n'a pas été trouvé'\n", argv[1], COMMAND_NAME);
		usage_cmd_and_exit();
	} else {
		function_name = token;
	}
	printf("Nom de la fonction : %s\n", function_name);
	
	size_t max_args = 64;
	size_t max_length_args = 128;
	char args[max_args][128];
	const char *delim_list = "{},";
	token = strtok(NULL, delim_list);
	size_t arg_index = 0;
	while (token != NULL) {
		printf("Argument n°%d : %s\n", arg_index+1, token);
		strcpy(args[arg_index++], token);
		token = strtok(NULL, delim_list);
	}
	// Le fichier à écrire
	char filename_out[FILENAME_MAX];
	snprintf(filename_out, sizeof(filename_out), "%s_main.%s", function_name, ASM_EXTENSION);
	FILE *fout = fopen(filename_out, "w");
	if (fout == NULL) {
		perror("fopen");
		exit(EXIT_FAILURE);
	}
	// Le fichier à lire
	char filename_in[FILENAME_MAX];
	snprintf(filename_in, sizeof(filename_in), "%s.%s", function_name, ASM_EXTENSION);
	FILE *fin = fopen(filename_in, "rb");
	if (fin == NULL) {
		fprintf(stderr, "Aucun fichier %s concenant la fonction %s n'a été " \
		"trouvé\n", filename_in, function_name);
		fprintf(stderr, "Veuillez ré-éxécuter le programme %s avec " \
		"votre fonction portant le même nom que le fichier .tex\n", PROGRAM_ALGO2ASIPRO);
		exit(EXIT_FAILURE);
	}
	
	fprintf(fout, "; Permet d'aller directement au label qui éxécute la fonction\n");
	fprintf(fout, "\tconst ax,%s\n", ASM_MAIN_FUNCTION);
	fprintf(fout, "\tjmp ax\n");
	
	// Ajout le fichier asm de la fonction au fichier principale (fout)
	size_t n_read;
	char buffer_read[BUFFER_MAX];
	size_t n = 4;
	printf("Lecture du fichier : %s\n", filename_in);
	while ((n_read = fread(buffer_read, sizeof(*buffer_read), n, fin)) == n) {
		fprintf(fout, "%s", buffer_read);
	}
	printf("Fin de lecture du fichier : %s\n", filename_in);
	
	fprintf(fout, "\n");
	fprintf(fout, ";;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(fout, "; Fonction principale\n");
	fprintf(fout, ";;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(fout, ":%s\n", ASM_MAIN_FUNCTION);
	fprintf(fout, "; Préparation de la pile\n");
	fprintf(fout, "\tconst bp,pile\n"); // bp : fond de la pile
	fprintf(fout, "\tconst sp,pile\n"); // sp : sommet de la pile
	fprintf(fout, "\tconst ax,2\n");
	fprintf(fout, "\tsub sp,ax\n"); // on fait la soustraction pour mettre le sommet de pile à - 2
		
	// Empile les arguments
	fprintf(fout, "; Empile les arguments de la fonction\n");
	for (int i = 0; i < arg_index; i++) {
		fprintf(fout, "\tconst ax,%s\n", args[i]);
		fprintf(fout, "\tpush ax\n");
	}
	// Appel de la fonction
	fprintf(fout, "; Appel de la fonction\n");
	fprintf(fout, "\tconst bx,%s\n", function_name);
	fprintf(fout, "\tcall bx\n");
	// Dépile les arguments
	for (int i = 0; i < arg_index; i++) {
		fprintf(fout, "; Dépile les arguments de la fonction\n");
		fprintf(fout, "\tpop bx\n");
	}
	fprintf(fout, "\tpush ax\n");

	// Affichage de la valeur
	fprintf(fout, "; Affichage la valeur calculée, qui se trouve normalement en sommet de pile\n");
	fprintf(fout, "\tcp ax,sp\n");
	fprintf(fout, "\tcallprintfd ax\n");
	fprintf(fout, "\tpop ax\n");
	fprintf(fout, "\tend\n");
	
	fprintf(fout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(fout, "; Début de stockage de la zone de pile\n");
	fprintf(fout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(fout, ":pile\n");
	fprintf(fout, "@int 0\n");
	fprintf(fout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	fprintf(fout, "; Fin de stockage de la zone de pile\n");
	fprintf(fout, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n");
	
	if (fclose(fout) == EOF) {
		perror("fclose");
	}
	
	if (fclose(fin) == EOF) {
		perror("fclose");
	}
	
	printf("==================================================================\n");
	printf("== Fichier assembleur ASIPRO généré : %s\n", filename_out);
	printf("== Il faut utiliser ASIPRO et SIPRO pour l'éxécuter\n");
	printf("== Fin du programme %s\n", argv[0]);
	printf("==================================================================\n");
	
	return EXIT_SUCCESS;
}

void usage_cmd_and_exit() {
	fprintf(stderr, "Usage   : %s %s\n", program_name, "’"COMMAND_NAME"{nom_fonction}{argument1,argument2,...}’");
	fprintf(stderr, "Exemple : %s %s\n", program_name, "’"COMMAND_NAME"{puissance}{2,3}’");
	exit(EXIT_FAILURE);
}
