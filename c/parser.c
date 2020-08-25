#include "y.tab.h"
#include "lex.yy.h"

#include "optr.h"
#include "mhook.h"

void *parser_new_scanner(void)
{
	yyscan_t scanner;
	if (yylex_init(&scanner))
		return NULL;
	
	return scanner;
}

struct optr_node *parser_parse(void *scanner, const char *tex)
{
	YY_BUFFER_STATE buf = yy_scan_string(tex, scanner);

	struct optr_node *root;
	yyparse(scanner, &root);

	yy_delete_buffer(buf, scanner);
	return root;
}

void parser_dele_scanner(void *scanner)
{
	yylex_destroy(scanner);
}

int parser_test()
{
	struct optr_node *root;
	void *scanner = parser_new_scanner();
	if (NULL == scanner)
		return 1;

	//char test[] = "0 - (1 + 2)";
	//char test[] = "2(-3)(-4)";
	//char test[] = "-(-2(-3)) 5";

	//char test[] = "a[c \\div 2b] = -(-5 + 1 - 3.14) + A \\times x - 2ax";
	//char test[] = "a^{1 + 2}";
	//char test[] = "\\frac 12 a";
	//char test[] = "12 + x *{12}";
	//char test[] = "\\sqrt 12 + 3";
	//char test[] = "\\sqrt 12 + 3";
	char test[] = "\\left | 1 - 2 \\right|";

	printf("TeX: %s\n", test);
	root = parser_parse(scanner, test);

	if (root) {
		optr_print(root);
		optr_release(root);
	}

	strcpy(test, "1 + 2 - 3");
	printf("TeX: %s\n", test);
	root = parser_parse(scanner, test);

	if (root) {
		optr_print(root);
		optr_release(root);
	}

	parser_dele_scanner(scanner);
	mhook_print_unfree();
	return 0;
}
