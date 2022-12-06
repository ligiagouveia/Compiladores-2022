
#pragma once

#include <stdio.h>
#include <stdbool.h>
#include <string.h>


enum noh_type {PROGRAM,stmts,
	ASSIGN,VAR, SUM, MINUS, MULTI,
	DIVIDE, MOSTRAR, POW,
	se, e, ou, senao, repitaate,
	LT, GT, LE, GE, EQ, NE,
	PAREN, STMT, INTEGER, FLOAT,
	IDENT, GENERIC,CE,CD,repitapara,
	pontovirgula,plusplus,minusminus,
	minusequal,plusequal};

static const char *noh_type_names[] = {
	"Programa","stmts", "=", "var","+", "-", "*",
	"/", "Mostrar", "^",
	"Se", "E", "Ou", "Se Nao", "Repita Ate",
	"<", ">", "<=", ">=", "==", "!=", "()","Stmt",
	"Int", "Float", "Ident", "Generic","{","}","repita Para",";","++","--","-=","+="
};

typedef struct {
	int intv;
	double dblv;
	char *ident;
} token_args;

typedef struct {
	char *nome;
	int token;
	bool exists;
	int colnr;
	int linenr;
} simbolo;

static int error_count = 0;
static int simbolo_qtd = 0;
static simbolo tsimbolos[100];
simbolo *simbolo_novo(char *nome, int token);
simbolo *simbolo_existe(char *nome);
void debug();

struct NohSintatico {
	int id;
	enum noh_type type;
	int childcount;
	double dblv;
	int intv;
	char *name;
	simbolo *sim;
	struct NohSintatico *children[1];
};
typedef struct NohSintatico NohSintatico;

typedef void (*visitor_action)(NohSintatico **root,	NohSintatico *no);

void collapse_stmts(NohSintatico **root,NohSintatico *no);

void check_declared_vars(NohSintatico **root,NohSintatico *no);
void checar_atribuicao_mesma_var(NohSintatico **root, NohSintatico *no);

void visitor_leaf_first(NohSintatico **root,
	visitor_action act);

NohSintatico *createNohSintatico(enum noh_type, int children);

void print(NohSintatico *root);
void print_rec(FILE *f, NohSintatico *root);