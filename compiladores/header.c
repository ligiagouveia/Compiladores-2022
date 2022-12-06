// header.c
#include <stdlib.h>
#include "header.h"

extern int yycol;
extern int yylineno ;

extern int errorc ;

NohSintatico *createNohSintatico(enum noh_type nt, int children) {
	static int IDCOUNT = 0;
	NohSintatico *newn = (NohSintatico*)calloc(1,
		sizeof(NohSintatico)+
		sizeof(NohSintatico*)*(children-1));
	newn->type = nt;
	newn->childcount = children;
	newn->id = IDCOUNT++;	
	return newn;
}

void print(NohSintatico *root) {
	FILE *f = fopen("output.dot", "w");
	
	fprintf(f, "graph {\n");
	print_rec(f, root);
	fprintf(f, "}\n");

	fclose(f);
}

const char *get_label(NohSintatico *no) {
	static char aux[100];
	switch (no->type) {
		case INTEGER:
			sprintf(aux, "%d", no->intv);
			return aux;
		case FLOAT:
			sprintf(aux, "%f", no->dblv);
			return aux;
		case IDENT:
			return no->name;
		default:
			return noh_type_names[no->type];
	}
}

void print_rec(FILE *f, NohSintatico *root) {
	fprintf(f, "N%d[label=\"%s\"];\n",
		root->id, get_label(root));
	for(int i = 0; i < root->childcount; i++) {
		print_rec(f, root->children[i]);
		fprintf(f, "N%d -- N%d;\n",
			root->id, root->children[i]->id);
	}
}

int search_symbol(char *nome) {
	// busca linear, não eficiente
	for(int i = 0; i < simbolo_qtd; i++) {
		if (strcmp(tsimbolos[i].nome, nome) == 0) {
			return i;
		}
	}
	return -1;
}



void checar_atribuicao_mesma_var(NohSintatico **root, NohSintatico *no)
{
	if(no->type == ASSIGN){
		NohSintatico *aux = no->children[0];
		NohSintatico *aux2 = no->children[1];
		if(aux->type == IDENT){
			if(aux2->type == IDENT && ((aux->intv == aux2->intv) ||(aux->dblv == aux2->dblv))){
				printf("Erro: [LINHA:%d|COLUNA:%d]  Variavel [%s] esta recebenco o mesmo valor.\n",yylineno, yycol, aux->name);
				error_count++;
			}
		}
	}
}




void collapse_stmts(NohSintatico **root,NohSintatico *no) {
	NohSintatico *nr = *root;

	if (nr->type == STMT && no->type == STMT) {
		int nsize = sizeof(NohSintatico);
		nsize += sizeof(NohSintatico*)* (nr->childcount-1);
		nsize += sizeof(NohSintatico*)* (no->childcount-1);
		nr = *root = realloc(*root,nsize);
		nr->childcount--;

		for(int i=0;i<no->childcount;i++){
			nr->children[nr->childcount] = no->children[i];
			nr->childcount++;
		}
		free(no);

	}
}

void check_declared_vars(NohSintatico **root,NohSintatico *no) {
	NohSintatico *nr = *root;

	if (no->type == VAR) {
		int s = search_symbol(no->children[0]->name);
		if (s != -1)
			tsimbolos[s].exists = true;
	}
	else if (no->type == IDENT) {
		if (nr->type == VAR && no == nr->children[0])
			return;

		int s = search_symbol(no->name);
		if (s == -1 || !tsimbolos[s].exists) {
			printf("Erro: [LINHA:%d|COLUNA:%d]  Variavel { %s } não declarada.\n",
				tsimbolos[s].linenr-1,tsimbolos[s].colnr, no->name);
			errorc++;
		}
	}
}


void visitor_leaf_first(NohSintatico **root,	visitor_action act) {
	NohSintatico *r = *root;
	for(int i = 0; i < r->childcount; i++) {
		visitor_leaf_first(&r->children[i],
			act);
		if (act != NULL)
			act(root, r->children[i]);
	}
}

simbolo *simbolo_novo(char *nome, int token) {
	tsimbolos[simbolo_qtd].nome = nome;
	tsimbolos[simbolo_qtd].token = token;
	tsimbolos[simbolo_qtd].exists = false;
	tsimbolos[simbolo_qtd].colnr = yycol;
	tsimbolos[simbolo_qtd].linenr = yylineno;
	simbolo *result = &tsimbolos[simbolo_qtd];
	simbolo_qtd++;
	return result;
}

simbolo *simbolo_existe(char *nome) {
	// busca linear, não eficiente
	for(int i = 0; i < simbolo_qtd; i++) {
		if (strcmp(tsimbolos[i].nome, nome) == 0)
			return &tsimbolos[i];
	}
	return NULL;
}

void debug() {
	printf("Variaveis:\n");
	for(int i = 0; i < simbolo_qtd; i++) {
		if(tsimbolos[i].exists)
			printf("\t%s\n", tsimbolos[i].nome);
	}
}