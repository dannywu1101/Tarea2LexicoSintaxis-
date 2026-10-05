%{
#include <iostream>
#define YYSTYPE double
int yylex();
void yyerror(const char *s) { std::cerr << "Error: " << s << std::endl; }
%}
%token NUM
%left '+' '-'
%left '*' '/'
%right UMENOS
%%
lineas : /* vacio */
       | lineas expr '\n'   { std::cout << "= " << $2 << std::endl; }
       | lineas '\n'
       | lineas error '\n'  { yyerrok; }
       ;
expr : expr '+' expr        { $$ = $1 + $3; }
     | expr '-' expr        { $$ = $1 - $3; }
     | expr '*' expr        { $$ = $1 * $3; }
     | expr '/' expr        { if ($3 == 0) { yyerror("division entre cero"); $$ = 0; }
                              else $$ = $1 / $3; }
     | '-' expr %prec UMENOS { $$ = -$2; }
     | '(' expr ')'         { $$ = $2; }
     | NUM                  { $$ = $1; }
     ;
%%
int main() { return yyparse(); }
