# Calculadora con Lex & Yacc en C++

Calculadora de expresiones aritméticas construida con **Lex** (analizador léxico) y **Yacc** (analizador sintáctico). El código que generan ambas herramientas se compila como C++ con `g++`.

Es el ejercicio práctico de una investigación sobre generadores automáticos de analizadores léxicos y sintácticos (*scanners* y *parsers*). Está basado en el ejemplo de calculadora del artículo original de Yacc (Johnson, 1975) y en los ejemplos del libro *lex & yacc* (Levine, Mason y Brown, 1992).

## Archivos

| Archivo | Descripción |
| --- | --- |
| `calc.l` | Especificación del analizador léxico (Lex) |
| `calc.y` | Gramática y acciones del analizador sintáctico (Yacc) |
| `Makefile` | Automatiza la generación y la compilación |
| `.gitignore` | Excluye los archivos generados y el ejecutable |

## Requisitos

- `lex` (o `flex`), `yacc` (o `bison`), `g++` y `make`.
- **macOS:** `xcode-select --install`
- **Linux (Ubuntu/Debian):** `sudo apt install flex bison g++ make`
- **Windows:** usar WSL (Ubuntu) e instalar lo mismo que en Linux.

## Compilación y ejecución

```bash
make        # genera el analizador y compila el ejecutable
./calc      # inicia la calculadora
```

Escribe una expresión por línea y presiona Enter. Para salir presiona `Ctrl + D`. Para borrar los archivos generados, usa `make clean`.

Para probar varias expresiones a la vez:

```bash
printf '2 + 3 * 4\n(2 + 3) * 4\n-5 + 10 / 4\n7 / 0\n2 + * 3\n1.5 * 2\n' | ./calc
```

Lo que hace el `Makefile` paso a paso:

```bash
yacc -d calc.y                       # genera y.tab.c (parser) y y.tab.h (códigos de token)
lex calc.l                           # genera lex.yy.c (scanner)
g++ -x c++ -o calc y.tab.c lex.yy.c  # compila ambos archivos como C++
```

## Cómo funciona

El programa trabaja en dos fases. El analizador sintáctico, `yyparse()` en `calc.y`, le pide tokens uno por uno al analizador léxico, `yylex()` en `calc.l`. Con cada token aplica las reglas de la gramática y ejecuta el código C++ asociado a cada regla.

### 1. Analizador léxico (`calc.l`)

El analizador léxico lee el texto de entrada y lo divide en *tokens* usando expresiones regulares:

| Patrón | Token que devuelve | Acción |
| --- | --- | --- |
| `[0-9]+(\.[0-9]+)?` | `NUM` | Convierte el texto a número con `atof` y lo guarda en `yylval` |
| `[-+*/()\n]` | El mismo carácter | Devuelve el operador, paréntesis o salto de línea |
| `[ \t]+` | (ninguno) | Ignora espacios y tabuladores |
| `.` | El mismo carácter | Cualquier otro carácter se pasa al parser, que lo marcará como error |

Otros detalles del archivo:

- **`#define YYSTYPE double`:** indica que los valores de los tokens son números reales. Debe coincidir con `calc.y`; en macOS, sin esta línea, la compilación falla.
- **`extern double yylval`:** es la variable con la que el scanner le pasa al parser el valor de cada número.
- **`yywrap()`:** devuelve 1 para indicar que no hay más archivos que leer al terminar la entrada.

### 2. Analizador sintáctico (`calc.y`)

La gramática reconoce una o más líneas, cada una con una expresión:

```
lineas : (vacío) | lineas expr '\n' | lineas '\n' | lineas error '\n'
expr   : expr '+' expr | expr '-' expr | expr '*' expr | expr '/' expr
       | '-' expr | '(' expr ')' | NUM
```

Cada regla tiene una acción en C++ que calcula su valor: `$$` es el resultado de la regla y `$1`, `$2`, `$3` son los valores de sus partes. Por ejemplo, `{ $$ = $1 + $3; }` suma las dos subexpresiones.

**Precedencia y asociatividad.** La gramática de `expr` es ambigua (`2 + 3 * 4` podría agruparse de dos formas). En lugar de reescribirla, se usan declaraciones de Yacc:

```
%left '+' '-'     // menor precedencia, asociativos por la izquierda
%left '*' '/'     // mayor precedencia
%right UMENOS     // menos unario, la precedencia más alta
```

Con ellas, Yacc resuelve los conflictos *shift/reduce* del analizador LALR(1). La regla `'-' expr %prec UMENOS` hace que `-5` se trate como negación y no como resta.

**Manejo de errores:**

- **División entre cero:** la acción de `/` revisa el divisor, muestra un mensaje y devuelve 0 en lugar de fallar.
- **Errores de sintaxis:** la regla `lineas error '\n'` usa el token especial `error` de Yacc para descartar la línea inválida. Luego `yyerrok` permite seguir leyendo las siguientes líneas.
- **`yyerror()`:** imprime los mensajes de error en `std::cerr`.

## Ejemplo de ejecución

| Entrada | Salida | Qué demuestra |
| --- | --- | --- |
| `2 + 3 * 4` | `= 14` | `*` tiene mayor precedencia que `+` |
| `(2 + 3) * 4` | `= 20` | Los paréntesis cambian el orden de evaluación |
| `-5 + 10 / 4` | `= -2.5` | Menos unario y números reales |
| `7 / 0` | `Error: division entre cero` | Validación dentro de una acción |
| `2 + * 3` | `Error: syntax error` | Recuperación de errores |
| `1.5 * 2` | `= 3` | El análisis continúa después de un error |

## Notas de portabilidad

- En macOS, `yacc` es GNU Bison en modo compatible y `g++` es `clang++`. La opción `-x c++` evita la advertencia *treating 'c' input as 'c++'*.
- Si tu sistema no tiene el comando `yacc`, cambia esa línea del `Makefile` por `bison -y -d calc.y`.
- Probado con Berkeley Yacc 2.0 y GNU Bison 3.8, ambos con flex 2.6.4.

## Referencias

- Lesk, M. E. y Schmidt, E. (1975). *Lex – A Lexical Analyzer Generator*. Bell Laboratories. https://cs.utexas.edu/~novak/lexpaper.htm
- Johnson, S. C. (1975). *Yacc: Yet Another Compiler-Compiler*. Bell Laboratories. https://www.cs.utexas.edu/~novak/yaccpaper.htm
- Levine, J. R., Mason, T. y Brown, D. (1992). *lex & yacc* (2.ª ed.). O'Reilly Media.
- Free Software Foundation. *GNU Bison Manual*. https://www.gnu.org/s/bison/manual/bison.html
