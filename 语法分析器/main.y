%{
#include<stdio.h>
#include"tree.h"
#include<stdlib.h>
#include"lex.yy.c"
struct Node* p;
void yyerror(char *s);
FILE *fout;
%}
%union{
         struct Node *token_p;
}
%type <token_p> program p_program con_des var_dess var_des var_d proc_des states con_defs con_def def_ids def_id proc_defs proc_head
%type <token_p> state assign_st comp_st if_st while_st repeat_st for_st procedure_st read_st write_st
%type <token_p> id ifs expr terms factors factor exprs ids
%token <token_p> IF THEN WHILE DO READ WRITE CALL BEGIN_ END CONST VAR PROCEDURE ODD FOR TO STEP REPEAT UNTIL CHAR REAL
%token <token_p> INTEGER FLOAT STRING IDENTIFIER OPERATOR SEM COMMA EQUAL COLON
%left <token_p> ADDSUB 
%left <token_p> MULTIDIV 
%left <token_p> DOT LP RP
%%
program : p_program DOT {printf("<程序> ::= <分程序>.\n");
                        p=newNode("program");insert(p,$1);insert(p,$2);$$=p;}
    ;
p_program : con_des var_des proc_des state 
            {printf("<分程序> ::= <常量说明部分><变量说明部分集><过程说明部分><语句>\n");
            p=newNode("p_program");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    ;
con_des : CONST con_defs SEM {printf("<常量说明部分> ::= CONST<常量定义集>;\n");
                                p=newNode("con_des");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | {printf("<常量说明部分> ::= <空>\n");
        p=newNode("NULL");$$=p;}
    ;
con_defs : con_defs COMMA con_def {printf("<常量定义集> ::= <常量定义集>,<常量定义>\n");
                                    p=newNode("con_defs");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | con_def {printf("<常量定义集> ::= <常量定义>\n");
                p=newNode("con_defs");insert(p,$1);$$=p;}
    ;
con_def : IDENTIFIER EQUAL INTEGER {printf("<常量定义> ::= IDENTIFIER:=INTEGER\n");
                                    p=newNode("con_def");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    ;
var_des : var_dess{printf("<变量说明部分> := <变量说明部分集>\n");p=newNode("var_des");insert(p,$1);$$=p;}
    | {printf("<变量说明部分> ::= <空>\n");
        p=newNode("NULL");$$=p;}    
    ;
var_dess : var_dess var_d SEM{printf("<变量说明部分集> ::= <变量说明部分集><变量说明>;\n");
                            p=newNode("var_dess");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | var_d SEM{printf("<变量说明部分集> ::= <变量说明>;\n");
                p=newNode("var_dess");insert(p,$1);insert(p,$2);$$=p;}
var_d : VAR def_ids {printf("<变量说明部分> ::= VAR<定义过程标识符集>;\n");
                            p=newNode("var_des");insert(p,$1);insert(p,$2);$$=p;}
    | CHAR def_ids {printf("<变量说明部分> ::= CHAR<定义过程标识符集>;\n");
                        p=newNode("var_des");insert(p,$1);insert(p,$2);$$=p;}
    | REAL def_ids {printf("<变量说明部分> ::= REAL<定义过程标识符集>;\n");
                        p=newNode("var_des");insert(p,$1);insert(p,$2);$$=p;}
    ;
def_ids : def_ids COMMA def_id {printf("<定义过程标识符集> ::= <定义过程标识符集>,<定义过程标识符>\n");
                                p=newNode("def_ids");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | def_id {printf("<定义过程标识符集> ::= <定义过程标识符>\n");
                p=newNode("def_ids");insert(p,$1);$$=p;}
    ;
def_id : IDENTIFIER LP INTEGER COLON INTEGER RP 
            {printf("<定义过程标识符> ::= IDENTIFIER’(’INTEGER,INTEGER’)’\n");
            p=newNode("def_id");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);insert(p,$5);insert(p,$6);$$=p;}
    | IDENTIFIER {printf("<定义过程标识符> ::= IDENTIFIER\n");
                    p=newNode("def_id");insert(p,$1);$$=p;}
    ;
proc_des : proc_defs {printf("<过程说明部分> ::= <过程说明部分集>\n");
                        p=newNode("proc_des");insert(p,$1);$$=p;}
    | {printf("<过程说明部分> ::= <空>\n");p=newNode("NULL");$$=p;}
    ;
proc_defs : proc_defs proc_head p_program SEM
            {printf("<过程说明部分集> ::= <过程说明部分集><过程首部><分程序>;\n");
                p=newNode("proc_defs");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    | proc_head p_program SEM {printf("<过程说明部分集> ::= <过程首部><分程序>;\n");
                                p=newNode("proc_defs");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    ;
proc_head : PROCEDURE IDENTIFIER SEM {printf("<过程首部> ::= PROCEDURE IDENTIFIER;\n");
                                        p=newNode("proc_head");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    ;
states : state {printf("<语句集> ::= <语句>\n");p=newNode("states");insert(p,$1);$$=p;}
    | states SEM state {printf("<语句集> ::= <语句集>;<语句>\n");
                        p=newNode("states");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    ;
state : assign_st {printf("<语句> ::= <赋值语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | comp_st {printf("<语句> ::= <复合语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | if_st {printf("<语句> ::= <条件语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | while_st {printf("<语句> ::= <当型循环语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | repeat_st {printf("<语句> ::= <REPEAT型循环语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | for_st {printf("<语句> ::= <FOR型语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | procedure_st {printf("<语句> ::= <过程调用语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | read_st {printf("<语句> ::= <读语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | write_st {printf("<语句> ::= <写语句>\n");p=newNode("state");insert(p,$1);$$=p;}
    | {printf("<语句> ::= <空>\n");p=newNode("NULL");$$=p;}
    ;
assign_st : id EQUAL expr {printf("<赋值语句> ::= <标识符>:=<表达式>\n");
                            p=newNode("assign_st");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    ;

id : IDENTIFIER LP IDENTIFIER RP {printf("<标识符> ::= IDENTIFIER’(‘IDENTIFIER’)’\n");
                                    p=newNode("id");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    | IDENTIFIER LP INTEGER RP {printf("<标识符> ::= IDENTIFIER’(‘INTEGER’)’\n");
                                p=newNode("id");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    | IDENTIFIER {printf("<标识符> ::= IDENTIFIER\n");p=newNode("id");insert(p,$1);$$=p;}
    ;
comp_st : BEGIN_ states SEM END {printf("<复合语句> ::= BEGIN<语句集>;END\n");
                            p=newNode("comp_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    | BEGIN_ proc_des END {printf("<复合语句> ::= BEGIN<过程说明部分>END\n");
                            p=newNode("comp_st");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    ;
ifs : expr OPERATOR expr {printf("<条件> ::= <表达式><关系运算符><表达式>\n");
                            p=newNode("ifs");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | ODD expr {printf("<条件> ::= ODD<表达式>\n");p=newNode("ifs");insert(p,$1);insert(p,$2);$$=p;}
    ;
if_st : IF ifs THEN state {printf("<条件语句> ::= IF<条件>THEN<语句>\n");
                            p=newNode("if_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    ;
expr : ADDSUB terms {printf("<表达式> ::= <加法运算符><项集>\n");p=newNode("expr");insert(p,$1);insert(p,$2);$$=p;}
    | terms {printf("<表达式> ::= <项集>\n");p=newNode("expr");insert(p,$1);$$=p;}
    ;
terms : terms ADDSUB factors {printf("<项集> ::= <项集><加法运算符><因子集>\n");
                                p=newNode("terms");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | factors {printf("<项集> ::= <因子集>\n");p=newNode("terms");insert(p,$1);$$=p;}
    ;
factors : factors MULTIDIV factor {printf("<因子集> ::= <因子集><乘法运算符><因子>\n");
                                    p=newNode("factors");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | factor {printf("<因子集> ::= <因子>\n");p=newNode("factors");insert(p,$1);$$=p;}
    ;
factor : LP expr RP {printf("<因子> ::= ’(‘<表达式>’)’\n");p=newNode("factor");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | id {printf("<因子> ::= <标识符>\n");p=newNode("factor");insert(p,$1);$$=p;}
    | INTEGER {printf("<因子> ::= INTEGER\n");p=newNode("factor");insert(p,$1);$$=p;}
    | FLOAT {printf("<因子> ::= FLOAT\n");p=newNode("factor");insert(p,$1);$$=p;}
    | STRING {printf("<因子> ::= STRING\n");p=newNode("factor");insert(p,$1);$$=p;}
    ;

while_st : WHILE ifs DO state {printf("<当型循环语句> ::= WHILE<条件>DO<语句>\n");
                                p=newNode("while_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    ;
repeat_st : REPEAT states UNTIL ifs {printf("<repeat型循环语句> ::= REPEAT<语句>UNTIL<条件>\n");
                                    p=newNode("repeat_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    ;
for_st : FOR assign_st TO expr STEP INTEGER DO state
        {printf("<for型循环语句> := FOR <赋值语句> TO <表达式> STEP INTEGER DO<语句>\n");
            p=newNode("for_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);insert(p,$5);insert(p,$6);insert(p,$7);insert(p,$8);$$=p;}
    | FOR assign_st TO expr DO state
        {printf("<for型循环语句> := FOR <赋值语句> TO <表达式> DO<语句>\n");
            p=newNode("for_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);insert(p,$5);insert(p,$6);$$=p;}
    ;
procedure_st : CALL IDENTIFIER {printf("<过程调用语句> ::= CALL IDENTIFIER\n");p=newNode("procedure_st");insert(p,$1);insert(p,$2);$$=p;}
    ;
read_st : READ LP ids RP {printf("<读语句> ::= READ’(‘<标识符集>’)’\n");p=newNode("read_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    ;
ids : ids COMMA id {printf("<标识符集> ::= <标识符集>,<标识符>\n");p=newNode("ids");insert(p,$1);insert(p,$2);$$=p;}
    | id {printf("<标识符集> ::= <标识符>\n");p=newNode("ids");insert(p,$1);$$=p;}
    ;
write_st : WRITE LP exprs RP {printf("<写语句> ::= WRITE’(‘<表达式集>’)’\n");
            p=newNode("write_st");insert(p,$1);insert(p,$2);insert(p,$3);insert(p,$4);$$=p;}
    ;
exprs : exprs COMMA expr {printf("<表达式集> ::= <表达式集>,<表达式>\n");p=newNode("exprs");insert(p,$1);insert(p,$2);insert(p,$3);$$=p;}
    | expr {printf("<表达式集> ::= <表达式>\n");p=newNode("exprs");insert(p,$1);$$=p;}
%%
void yyerror(char* s)
{    
     FILE* errdir=NULL;
     errdir=fopen("stderr","w");
     if(fout!=NULL)
     fprintf(fout,"Error.");
     fprintf(errdir,"line %d num %d error.\n",num_lines,num_chars-yyleng);
     fclose(fout);
     fclose(errdir);
     exit(1);
}
int main(int argc,char *argv[])
{    
     FILE* fin=NULL;
     extern FILE* yyin;
     fin=fopen(argv[1],"r"); 
     fout=fopen(argv[2],"w");
     if(fin==NULL)
     { 
         printf("cannot open reading file.\n");
         return -1;
     }
     yyin=fin;
     yyparse();
     //printTree(p,fout);
     printtree(p,fout);
     strncpy(p->dotname,p->label,20);
     FILE *output=fopen("tree.dot","w");
     fprintf(output,"digraph g {\n");
     fprintf(output,"%s [label=\"%s\"];\n",p->dotname,p->label);
     treedot(p,output);
  	 fprintf(output,"}");
     fclose(fin);
     fclose(fout);
     fclose(output);
     return 0;
}