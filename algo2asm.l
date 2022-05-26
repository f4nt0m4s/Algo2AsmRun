%{
	#include <stdio.h>
	#include <limits.h>
	#include <stdbool.h>
	#include <types.h>
	#include <flex_util.h>
	#include "algo2asm.tab.h"
	static size_t numlign = 1;
%}
/* Commentaire en C */
%x comment
	
KEYWORD_PREFIX			[\\]
KEYWORD_BEGIN_COMMAND	BEGIN|begin
KEYWORD_END_COMMAND		END|end
KEYWORD_SET_COMMAND		SET|set
KEYWORD_IF_COMMAND		IF|if
KEYWORD_ELSE_COMMAND	ELSE|else
KEYWORD_FI_COMMAND		FI|fi
KEYWORD_DOWHILE_COMMAND	DOWHILE|dowhile
KEYWORD_OD_COMMAND		OD|od
KEYWORD_RETURN_COMMAND	RETURN|return
KEYWORD_INCR_COMMAND	INCR|incr
KEYWORD_DECR_COMMAND	DECR|decr
KEYWORD_DOFORI_COMMAND	DOFORI|dofori
/* Commentaire en Latex */
KEYWORD_COM_COMMAND		COM|com
	
%option noyywrap
%%
"/*"					BEGIN(comment);
<comment>[^*\n]*		/* consomme ce qui n'est pas un '*' */
<comment>"*"+[^*/\n]*	/* consomme les * qui ne sont pas suivies par un / */
<comment>\n				
<comment>"*"+"/"		BEGIN(INITIAL);
{KEYWORD_PREFIX}{KEYWORD_COM_COMMAND}"{".*"}"	{ printf("COM\n"); }
	
{KEYWORD_PREFIX}{KEYWORD_BEGIN_COMMAND}		{ printf("BEGIN\n");	return BEGIN_COMMAND;		}
{KEYWORD_PREFIX}{KEYWORD_END_COMMAND}		{ printf("END\n");		return END_COMMAND;			}
{KEYWORD_PREFIX}{KEYWORD_SET_COMMAND}		{ printf("SET\n");		return SET_COMMAND;			}
{KEYWORD_PREFIX}{KEYWORD_IF_COMMAND}		{ printf("IF\n");		return IF_COMMAND;			}
{KEYWORD_PREFIX}{KEYWORD_ELSE_COMMAND}		{ printf("ELSE\n");		return ELSE_COMMAND;		}
{KEYWORD_PREFIX}{KEYWORD_FI_COMMAND}		{ printf("FI\n");		return FI_COMMAND;			}
{KEYWORD_PREFIX}{KEYWORD_DOWHILE_COMMAND}	{ printf("DOWHILE\n");	return DOWHILE_COMMAND;		}
{KEYWORD_PREFIX}{KEYWORD_OD_COMMAND}		{ printf("OD\n");		return OD_COMMAND;			}
{KEYWORD_PREFIX}{KEYWORD_RETURN_COMMAND}	{ printf("RETURN\n");	return RETURN_COMMAND;		}
{KEYWORD_PREFIX}{KEYWORD_INCR_COMMAND}		{ printf("INCR\n");		return INCR_COMMAND;		}
{KEYWORD_PREFIX}{KEYWORD_DECR_COMMAND}		{ printf("DECR\n");		return DECR_COMMAND;		}
{KEYWORD_PREFIX}{KEYWORD_DOFORI_COMMAND}	{ printf("DOFORI\n");	return DOFORI_COMMAND;		}
	
"&&"						{ printf("AND\n");	return AND;			}
"||"						{ printf("OR\n");	return OR;			}
"=="						{ printf("EQ\n");	return EQ;			}
"!="						{ printf("NEQ\n");	return NEQ;			}
	
[[:digit:]]+				{ printf("NUMBER\n"); string_to_int(&yylval.integer, yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]*		{ sprintf(yylval.id, "%s", yytext); return IDENTIFIER; }
	
">"							{ return '>'; }
"<"							{ return '<'; }
";"							{ return ';'; }
("{"|"<%")					{ return '{'; }
("}"|"%>")					{ return '}'; }
","							{ return ','; }
":"							{ return ':'; }
"="							{ return '='; }
"("							{ return '('; }
")"							{ return ')'; }
("["|"<:")					{ return '['; }
("]"|":>")					{ return ']'; }
"."							{ return '.'; }
"&"							{ return '&'; }
"!"							{ return '!'; }
"~"							{ return '~'; }
"-"							{ return '-'; }
"+"							{ return '+'; }
"*"							{ return '*'; }
"/"							{ return '/'; }
"%"							{ return '%'; }
"^"							{ return '^'; }
"|"							{ return '|'; }
"?"							{ return '?'; }

[[:blank:]]				{ }
[\t\v\f] 				{ }
\n						{ numlign++; }
.						{ return yytext[0]; }
%%
	
