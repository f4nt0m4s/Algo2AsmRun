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

#ifndef _STABLE_H
#define _STABLE_H

#include "types.h"

symbol_table_entry *search_symbol_table(const char *name);
symbol_table_entry *new_symbol_table_entry(const char *name);
void free_first_symbol_table_entry(void);
// Return a copy of current symbol table
symbol_table_entry *get_symbol_table();

void incr_num_scope();
void decr_num_scope();
unsigned int get_num_scope();

void incr_count_args();
void reset_count_args();
unsigned char get_count_args();

#endif
