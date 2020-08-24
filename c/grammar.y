%{
#include "y.tab.h"
#include "lex.yy.h"

#include "optr.h"

int yyerror(void*, struct optr_node**, const char*);

#define YYPARSE_PARAM yyscan_t scanner
#define YYLEX_PARAM scanner

#define COMM_ATTACH(_root, _child) \
	if (NULL != _child) { \
		if (_child->token == _root->token) \
			optr_pass_children(_root, _child); \
		else \
			optr_attach(_root, _child); \
	} do {} while (0)

#define REVERSE_SIGN(_nd) \
	if (_nd) _nd->sign *= -1.f; do {} while (0)
%}

%union {
	struct optr_node *nd;
}

%destructor {
	if ($$) {
		optr_release($$);
		$$ = NULL;
	}
} <nd>

%define api.pure full
%define parse.error verbose

%lex-param {void *scanner}
%parse-param {void *scanner}
%parse-param {struct optr_node **root}
/*
 * Above statements will change yyparse() and yylex() from no arguments to these:
 * yyparse(yyscan_t *scanner)
 * yylex(YYSTYPE *yylval_param, yyscan_t yyscanner)
 */

%token _EOL
%token <nd> NUM
%token <nd> VAR
%token _EQ
%token _ADD
%token _MINUS
%token _DIV
%right _SUP _SUB
%token _TIMES _CDOT
%token _STAR
%token _SQRT

%start start
%type <nd> doc
%type <nd> sum
%type <nd> term
%type <nd> product
%type <nd> factor
%type <nd> atom

%left _NULL_REDUCE
%left _ADD _MINUS
%left _TIMES _CDOT

%right _FRAC
%nonassoc _L_TEX _R_TEX

%%
start: doc {
	*root = $1;
}
;

doc: sum {
	$$ = $1;
}
| sum _EQ sum {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '=';

	optr_attach(op, $1);
	optr_attach(op, $3);
	$$ = op;
}
;

sum: %prec _NULL_REDUCE {
	$$ = NULL;
}
| term {
	$$ = $1;
}
| sum _ADD term {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '+';

	COMM_ATTACH(op, $1);
	COMM_ATTACH(op, $3);
	$$ = op;
}
| sum _MINUS term {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '+';

	COMM_ATTACH(op, $1);
	COMM_ATTACH(op, $3);
	REVERSE_SIGN($3);
	$$ = op;
}
;

term: product {
	$$ = $1;
}
| term _DIV product {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '/';

	optr_attach(op, $1);
	optr_attach(op, $3);
	$$ = op;
}
;

product: factor {
	$$ = $1;
}
| product factor {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '*';

	COMM_ATTACH(op, $1);
	COMM_ATTACH(op, $2);
	$$ = op;
}
| product _TIMES factor {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '*';

	COMM_ATTACH(op, $1);
	COMM_ATTACH(op, $3);
	$$ = op;
}
| product _CDOT factor {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '*';

	COMM_ATTACH(op, $1);
	COMM_ATTACH(op, $3);
	$$ = op;
}
;

factor: atom {
	$$ = $1;
}
| atom _SUP atom {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '^';

	COMM_ATTACH(op, $1);
	COMM_ATTACH(op, $3);
	$$ = op;
}
| atom _SUB atom {
	/* TODO */
	if ($3)
		optr_release($$);

	$$ = $1;
}
| _FRAC atom atom {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = '/';

	optr_attach(op, $2);
	optr_attach(op, $3);
	$$ = op;
}
;

atom: NUM {
	$$ = $1;
}
| VAR {
	$$ = $1;
}
| _L_TEX sum _R_TEX {
	$$ = $2;
}
| _STAR _L_TEX NUM _R_TEX {
	$3->is_wildcards = 1;
	$$ = $3;
}
| _SQRT atom {
	struct optr_node *op = optr_alloc(OPTR_NODE_TOKEN);
	op->token = 's';
	optr_attach(op, $2);
	$$ = op;
}
;
%%

int yyerror(void *scanner, struct optr_node **root, const char *msg)
{
	fprintf(stderr, "[Error] %s\n", msg);
	*root = NULL;
	return 0;
}
/*
     | "(" sum ")"                        -> grp
     | "[" sum "]"                        -> grp
     | "\\left" "|" sum "\\right" "|"     -> abs
*/
