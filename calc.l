%{
#include <cstdlib>
#define YYSTYPE double   // mismo tipo de valor que en calc.y
extern double yylval;    // valor del token, definido por yacc
#include "y.tab.h"
%}
%%
[0-9]+(\.[0-9]+)?   { yylval = atof(yytext); return NUM; }
[-+*/()\n]          { return yytext[0]; }
[ \t]+              { /* ignorar espacios */ }
.                   { return yytext[0]; }
%%
int yywrap() { return 1; }   // fin de la entrada
