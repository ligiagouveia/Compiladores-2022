%{
#include <stdio.h>
#include <stdlib.h>
#include "header.h"
#include <stdbool.h>
#include <string.h>
int yyerror(const char *s) ;
int yylex (void)           ;
int errorc=0;

int yycol = 0;
extern int yylineno;


%}

%union {
	token_args args ;
	struct NohSintatico *no  ;
}

%define parse.error verbose

%token TOK_MOSTRAR TOK_repitaate TOK_e TOK_ou TOK_se TOK_senao TOK_repitapara 
%token <args> TOK_IDENT TOK_INTEGER TOK_FLOAT TOK_PLUSPLUS TOK_MINUSMINUS TOK_MINUSEQUAL TOK_PLUSEQUAL TOK_VAR
%token TOK_LITERAL 

%type <no> program stmts stmt atribuicao aritmetica
%type <no> logical se repitaate lfactor lterm senao repitapara
%type <no>   factor


%nonassoc SEx
%nonassoc TOK_senao
%start program

%%
program : stmts 
        {
			if(errorc>0)
				printf("%d erro(s) encontrados(s)\n",errorc);
			else{
				printf("Programa Reconhecido\n");
				NohSintatico *program = createNohSintatico(PROGRAM, 1) ;
				program->children[0] = $1;
				visitor_leaf_first(&program,collapse_stmts);
				visitor_leaf_first(&program,check_declared_vars);		
				visitor_leaf_first(&program,checar_atribuicao_mesma_var);		

				print(program);
				debug();


		}
		 }
;

stmts : stmts stmt {
	NohSintatico *n = $1                     ;
	n = (NohSintatico*)realloc(n, sizeof(NohSintatico) + sizeof(NohSintatico*) * n->childcount)  ;
			n->children[n->childcount] = $2 ;
			n->childcount++                 ;
			$$ = n                          ;
		}
| stmt {
	 		$$ = createNohSintatico(STMT, 1)       ;
			$$->children[0] = $1            ;
		}


;



stmt : atribuicao {
	 		$$ = $1;
	 }
	 
| TOK_MOSTRAR aritmetica {	
	 		$$ = createNohSintatico(MOSTRAR, 1) ;
			$$->children[0] = $2;

	 }

;

atribuicao : TOK_VAR TOK_IDENT '=' aritmetica {			
			simbolo *s = simbolo_existe($2.ident);
			if(!s)
				s = simbolo_novo($2.ident, IDENT);	
			else{
				printf("Erro: [LINHA:%d|COLUNA:%d]  Variavel Ja Declarada na linha e coluna [%d:%d].\n",yylineno,yycol,s->linenr,s->colnr);
			}
			
			$$ = createNohSintatico(VAR,2);
			
			NohSintatico *nv = createNohSintatico(IDENT,0);		
						
			
			nv->name= $2.ident;								
			nv->sim=s;

			

			//$$->children[0] = createNohSintatico(ASSIGN, 2);			
			$$->children[0]=nv;			
			$$->children[1]=$4;
			//$$->children[1]=$4;
			

			//$$->children[1] = $4;			
			
}| TOK_IDENT '=' aritmetica {	
			$$ = createNohSintatico(ASSIGN, 2);
			NohSintatico *aux = createNohSintatico(IDENT, 0)     ;
			aux->name = $1.ident                ;
			$$->children[0] = aux               ;	
			$$->children[1] = $3               ;	
			
}

| TOK_IDENT TOK_PLUSPLUS{	
	 		$$ = createNohSintatico(plusplus, 1)         ;
			NohSintatico *aux = createNohSintatico(IDENT, 0)     ;
			aux->name = $1.ident                ;
			$$->children[0] = aux               ;		

				
			
}
| TOK_IDENT TOK_MINUSMINUS{
	 		$$ = createNohSintatico(minusminus, 1)         ;
			NohSintatico *aux = createNohSintatico(IDENT, 0)     ;
			aux->name = $1.ident                ;
			$$->children[0] = aux               ;	

						
}
| TOK_IDENT TOK_MINUSEQUAL aritmetica {
	 		$$ = createNohSintatico(minusequal, 2)         ;
			NohSintatico *aux = createNohSintatico(IDENT, 0)     ;
			aux->name = $1.ident                ;
			$$->children[0] = aux               ;	
			$$->children[1] = $3                ;	
					
}
| TOK_IDENT TOK_PLUSEQUAL aritmetica {
	 		$$ = createNohSintatico(plusequal, 2)         ;
			NohSintatico *aux = createNohSintatico(IDENT, 0)     ;
			aux->name = $1.ident                ;
			$$->children[0] = aux               ;		
			$$->children[1] = $3                ;
	
				
}
      			| se{ $$ = $1;} 
      			| repitaate { $$ = $1;}
				| repitapara { $$ = $1;}
				
				
	 
;

se : TOK_se '(' logical ')' stmt   %prec SEx{
		$$ = createNohSintatico(se, 2);		
		$$->children[0] = $3;
		$$->children[1] = $5;
		
			}

| TOK_se '(' logical ')' stmt  senao{
		$$ = createNohSintatico(se, 3);
		$$->children[0] = $3;
		$$->children[1] = $5;
		$$->children[2] = $6;
		
      }

| TOK_se '(' logical ')' '{' stmts '}' %prec SEx{
		$$ = createNohSintatico(se, 2);
		$$->children[0] = $3;
		$$->children[1] = $6;			
      }

| TOK_se '(' logical ')' '{' stmts '}' senao{				
		$$ = createNohSintatico(se, 3);					
	    $$->children[0] = $3;
		$$->children[1] = $6;	
		$$->children[2] = $8;
	        
	        }     
	   
		   				
;

senao :  TOK_senao stmt{							
	    	$$ = createNohSintatico(senao, 1);					
	    	$$->children[0] = $2;				
			 }
		  | TOK_senao '{' stmts'}' { 
			$$ = createNohSintatico(senao, 1);					
	    	$$->children[0] = $3;			
			 }
		
		  ;

repitaate: TOK_repitaate '(' logical ')' '{' stmts '}'{
		$$ = createNohSintatico(repitaate, 2);
		$$->children[0] = $3;
		$$->children[1] = $6;	
		}
		| TOK_repitaate '(' logical ')' stmt {
		$$ = createNohSintatico(repitaate, 2);
		$$->children[0] = $3;
		$$->children[1] = $5;	
		}		 
		;


repitapara: TOK_repitapara '('atribuicao';'logical';'atribuicao ')' '{' stmts '}'{
	$$ = createNohSintatico(repitapara, 4);
	$$->children[0] = $3;
	$$->children[1] = $5;	
	$$->children[2] = $7;
	$$->children[3] = $10;

}|TOK_repitapara '('atribuicao';'logical';'atribuicao ')'  stmt {
	$$ = createNohSintatico(repitapara, 4);
	$$->children[0] = $3;
	$$->children[1] = $5;
	$$->children[2] = $7;
	$$->children[3] = $9;	
}
;




logical : logical TOK_ou lterm	{
		$$ = createNohSintatico(ou, 2)   ;
		$$->children[0] = $1     ;
		$$->children[1] = $3     ;		
							}
		| lterm				
		{
			$$ = $1	;
		}
		;

lterm	: lterm TOK_e lfactor	{
		$$ = createNohSintatico(e, 2) ;
		$$->children[0] = $1    ;
		$$->children[1] = $3    ;
		}
		| lfactor	
		{
			$$ = $1 ;
		}
		;

lfactor : '(' logical ')'	{
$$ = $2 ;
		}
		| aritmetica '>' aritmetica		{
		$$ = createNohSintatico(GT, 2)     ;
		$$->children[0] = $1       ;
		$$->children[1] = $3       ;
							}
		| aritmetica '<' aritmetica		{
		$$ = createNohSintatico(LT, 2)     ;
		$$->children[0]= $1        ;
		$$->children[1] = $3       ;
		}
	
		| aritmetica '=''=' aritmetica	{
		$$ = createNohSintatico(EQ, 2)     ;
		$$->children[0] = $1       ;
		$$->children[1] = $4       ;
		}
		| aritmetica '>''=' aritmetica	{
		$$ = createNohSintatico(GE, 2)     ;
		$$->children[0] = $1       ;
		$$->children[1] = $4       ;
							}
		| aritmetica '<''=' aritmetica	{
		$$ = createNohSintatico(LE, 2)     ;
		$$->children[0] = $1       ;
		$$->children[1] = $4       ;
							}
		
		| aritmetica '!''=' aritmetica  {
                $$ = createNohSintatico(NE, 2)     ;
                $$->children[0] = $1       ;
                $$->children[1] = $4       ;
         }
		;

aritmetica : factor '+' factor {				
	 			$$ = createNohSintatico(SUM, 2);
				$$->children[0] = $1           ;
				$$->children[1] = $3           ;
				
			
	 		}
		 | factor '-' factor {
	 			$$ = createNohSintatico(MINUS, 2)     ;
				$$->children[0] = $1           ;
				$$->children[1] = $3           ;
	 		}
		
		| factor '*' factor {
	 			$$ = createNohSintatico(MULTI, 2)     ;
				$$->children[0] = $1           ;
				$$->children[1] = $3           ;
	 		}

		| factor '/' factor {
	 			$$ = createNohSintatico(DIVIDE, 2)     ;
				$$->children[0] = $1           ;
				$$->children[1] = $3          ;					
				if($3->intv==0)		
					printf("Erro: [LINHA:%d|COLUNA:%d]  Divisao por Zero { %d/%d }.\n",yylineno,yycol,$1->intv,$3->intv);
				

	 		}
		| factor '^' factor {
	 		$$ = createNohSintatico(POW, 2) ;
			$$->children[0] = $1     ;
			$$->children[1] = $3     ;
		}
		
		
		
		| factor {
						$$ = $1 ;
					}
				;

factor : '(' aritmetica ')' {
			$$ = $2                      ;
			
		 }
| TOK_IDENT {	
	 		$$ = createNohSintatico(IDENT, 0)   ;
			$$->name = $1.ident;
			simbolo *s = simbolo_existe($$->name);
				if(!s)		
					s= simbolo_novo($$->name, $$->type);
			
	 }
	 | TOK_INTEGER {
	 		$$ = createNohSintatico(INTEGER, 0) ;
			$$->intv = $1.intv           ;
	 	 }
	 | TOK_FLOAT {
	 		$$ = createNohSintatico(FLOAT, 0)   ;
			$$->dblv = $1.dblv           ;
	 	 }
	
	;

%%

int yyerror(const char *s) {
printf("Erro na linha %d %s\n",yylineno, s) ;
	return 1  ;
}
