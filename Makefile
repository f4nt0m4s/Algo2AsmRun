SHELL=/bin/sh
LEX=flex
YACC=bison
CC=gcc
CFLAGS=-g -std=c11 -pedantic -Wall
LDFLAGS=-lfl -lm
LEXOPTS=-D_POSIX_SOURCE -DYY_NO_INPUT --nounput
YACCOPTS=-Wcounterexamples -Wconflicts-sr
INCDIR=inc
PROG_ASIPRO=algo2asm
PROG_SIPRO=run

#-------------#
# ALGO2ASIPRO #
#-------------#
$(PROG_ASIPRO): lex.yy.o $(PROG_ASIPRO).tab.o stable.o label.o bison_util.o flex_util.o
	$(CC) $+ -o $@ $(LDFLAGS)

lex.yy.c: $(PROG_ASIPRO).l $(PROG_ASIPRO).tab.h
	$(LEX) $(LEXOPTS) $<

lex.yy.h: $(PROG_ASIPRO).l
	$(LEX) $(LEXOPTS) --header-file=$@ $<

$(PROG_ASIPRO).tab.c $(PROG_ASIPRO).tab.h: $(PROG_ASIPRO).y lex.yy.h
	$(YACC) $(YACCOPTS) $< -d -v --graph

%.o: %.c
	$(CC) -DYYDEBUG $(CFLAGS) $< -c -I $(INCDIR)

#-----------#
# RUN2SIPRO #
#-----------#
$(PROG_SIPRO):
	$(CC) -o $@ $@.c

#-------#
# CLEAN #
#-------#
clean:
	rm -f $(PROG_EXECUTE) $(PROG_ASIPRO) $(PROG_SIPRO) *.o lex.yy.* $(PROG_ASIPRO).tab.* *.err *.output *.out *.dot *.gv *.asm
	
# =========================================================================
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Tutoriel Makefile ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# =========================================================================

# Variables pour les règles générales (mais inutile pour ce projet) \
EXEC = main \
SRC = $(wildcard *.c) \
OBJ = $(SRC:.c=.o) \
#------------------#
# Règles générales #
#------------------#
#Règles pour compiler, édition des liens et éxécuter \
all : $(EXEC) \
	./$(EXEC) \
 Création du fichier éxécutable \
$(EXEC) : $(OBJ) \
	$(CC) -o $(EXEC) $(OBJDIR)/$(OBJ) $(LDFLAGS) \
 Génération des fichiers objets \
$(OBJDIR)/%.o : %.c \
	$(CC) -c $(SRC) $(CFLAGS) \
Les règles générales sont inutiles car pour ce projet.

# Tutoriel : https://www.youtube.com/watch?v=-riHEHGP2DU&ab_channel=FormationVid%C3%A9o

# ========================= 
# ~~ Variables spéciales ~~
# =========================

# $@ : $@ référence le nom de la cible
# $< : nom de la première dépendance
# $^ : la liste des dépendances
# $? : la liste des dépendances plus récentes que la cible
# $* : le nom du fichier sans son extension

# %.c : Tous les fichiers .c
# %.o : Tous les fichiers .o
