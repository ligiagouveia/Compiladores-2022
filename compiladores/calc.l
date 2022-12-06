
%{
	#include <stdio.h>
	#include "header.h"
	#include "calc.tab.h"
	extern int yycol;
    #define YY_USER_ACTION yycol +=yyleng;
	
	
	
%}

%option yylineno

D	[0-9]
L	[a-zA-Z_]

%% 

[ \t \r]			{}
[ \n]				    {yycol=0;}
"mostrar"				{ return TOK_MOSTRAR; }
"="					{ return '=';  }
"*"					{ return '*'; }
"/"					{ return '/'; }
"+"					{ return '+'; }
"-"					{ return '-'; }
"("					{ return '('; }
")"					{ return ')'; }
"^"					{ return '^'; }
"{"					{ return '{'; }
"}"					{ return '}'; }
";"					{ return ';'; }
"<"					{ return '<'; }
"++"					{ return TOK_PLUSPLUS; }
"--"					{ return TOK_MINUSMINUS; }
"-="					{ return TOK_MINUSEQUAL; }
"+="					{ return TOK_PLUSEQUAL; }
"int"					{ return TOK_INTEGER; }
"var"					{ return TOK_VAR; }


 

[<>!{}]		{ return yytext[0]; }
"e"		{ return TOK_e; }
"ou"		{ return TOK_ou; }
"se"		{ return TOK_se; }
"senao"		{ return TOK_senao; }

"repitaate"		{ return TOK_repitaate; }
"repitapara"		{ return TOK_repitapara; }



{D}+			{ yylval.args.intv = atoi(yytext);
						return TOK_INTEGER; }

{D}+\.{D}+			{ yylval.args.dblv = atof(yytext);
									return TOK_FLOAT; }

{L}({L}|{D})*		{ yylval.args.ident = strndup(yytext, yyleng);
									return TOK_IDENT; }
 /* [a-zA-Z_][a-zA-Z0-9_]* {} */


 /* comentário */
.					{ printf("Invalid caracter: %c.\n", yytext[0]); }

%%

int yywrap() {
	return 1;
}

int main(int argc, char *argv[]) {
	
	if (argc <= 1) {
		printf("%s [file]\n", argv[0]);
		return 1;
	}

	FILE *f = fopen(argv[1], "r");
	yyin = f;
	yyparse();
	fclose(f);
	return 0;
}

