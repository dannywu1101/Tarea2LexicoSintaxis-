# Calculadora con Lex & Yacc (compilada como C++)
calc: calc.l calc.y
	yacc -d calc.y
	lex calc.l
	g++ -x c++ -o calc y.tab.c lex.yy.c

clean:
	rm -f calc y.tab.c y.tab.h lex.yy.c
