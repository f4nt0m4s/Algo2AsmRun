/*
  Copyright 2016 Nicolas Bedon 
  This file is part of CASIPRO.

  CASIPRO is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  CASIPRO is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with CASIPRO.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdlib.h>
#include <string.h>
#include "types.h"
#include <stdio.h>

static symbol_table_entry *symbol_table = NULL;

symbol_table_entry *search_symbol_table(const char *name) {
  if (name == NULL) return NULL;
  symbol_table_entry *ste = symbol_table;
  for ( ste = symbol_table;
        ste!=NULL && strcmp(ste->name, name);
        ste = ste->next)
    ;
  return ste;
}

symbol_table_entry *new_symbol_table_entry(const char *name) {
  if (name == NULL) return NULL;
  symbol_table_entry *n;
  if ((n = malloc(sizeof(symbol_table_entry))) == NULL) {
    fail_with("new_symbol_table_entry: %s", strerror(errno));
  } else {
    if ((n->name = malloc(strlen(name)+1)) == NULL) {
      fail_with("new_symbol_table_entry: %s", strerror(errno));
    } else {
      strcpy((char *)(n->name), name);
      // Last declared symbol needs to be first in the list,
      // in order to have the scope of local variables correctly
      // taken into account
      n->next = symbol_table;
      symbol_table = n;
    }
  }
  return n;
}

void free_first_symbol_table_entry(void) {
  symbol_table_entry *ste = symbol_table->next;
  free(symbol_table);
  symbol_table = ste;
}

symbol_table_entry *get_symbol_table() {
	if (symbol_table == NULL) return NULL;
	symbol_table_entry *ste = malloc(sizeof(symbol_table_entry));
	if ((ste = malloc(sizeof(symbol_table_entry))) == NULL) {
		fail_with("get_symbol_table: %s", strerror(errno));
	}
	memcpy(ste, symbol_table, sizeof(symbol_table_entry));
	return ste;
}

// Compteur du numéro du bloc contenant les définitions et instructions
static unsigned int num_scope = 0;
void incr_num_scope() {
	num_scope++;
}
void decr_num_scope() {
	num_scope--;
}
unsigned int get_num_scope() {
	return num_scope;
}
	
// Compteur de nombre d'arguments passés à la fonction
// unsigned char car max arguments en C = 127
static unsigned char count_args = 0;
void incr_count_args() {
	count_args++;
}
void reset_count_args() {
	count_args = 0;
}
unsigned char get_count_args() {
	return count_args;
}

