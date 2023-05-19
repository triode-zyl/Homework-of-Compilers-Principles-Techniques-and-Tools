%{

#include <stdio.h>
#include <stdlib.h>
//#include <ctype.h>
#include <string.h>
#include <stdbool.h>
#include "definition.h"
//#include "lex.yy.c"
FILE *fp;  //指向输出类pcode文件的指针
extern int row_num, col_num;  //行数和列数


typedef struct{ 
      enum KIND{Const,Int,Char,Real,Proc} kind;         
      char* name;
      DATA data;
      int level;        //所在层次
      int addr;         //变量的偏移地址
      int previous;     //指向的下一个地址
      bool if_array;
      int array_low,array_up;
}symbol; 

#define MAX_SYMBOL_TABLE_SIZE 50
typedef symbol* sym;

typedef struct{
      int top;
      symbol index[MAX_SYMBOL_TABLE_SIZE];
}symbol_table;


symbol_table symtable;  //符号栈
int display_stack[20];  //display栈
int display_top = 0;   //display的栈顶
int now_Level = 0;    //当前的层数
int addr = 3;     //记录每个变量在运行栈中相对本过程基地址的偏移量

typedef struct{
      enum f{LIT, LODI, LODF, STOI, STOF, CAL, INT, JMP, JPC, OPR, I2R, R2I} f;
      int l;
      int a;
}instruction; 

#define STACKSIZE 200
instruction code[STACKSIZE];
int code_line = 0;
char *fname[]={"LIT","LODI","LODF","STOI","STOF","CAL","INT","JMP","JPC","OPR","I2R","R2I"};

int bkpchpos[50];  //记录回填的位置
int bkpchpos_top = -1;  //回填栈顶

#define MAXPRONUM 20
typedef struct{
      char *proname;
      int l;  //层差
      int pos;
}prostk; 
prostk prostack[MAXPRONUM];
int prostktop = -1;  //过程栈栈顶

int whilepos[10];  //记录循环的code_line
int whiletop = -1;

int forpos[10];
int fortop = -1;

int repeatpos[10];
int repeattop = -1;

//函数声明部分
int yylex();
int yyerror(char *s);

void init();

void symtable_init();
void symtable_push(char *id_name, int k, DATA v, bool if_array, int array_low, int array_up);
void symtable_pop();
int if_declared();
int symtable_size();
int find_sign(char *sign_name);
int findpro(char *pname);
void Backpatch(int p, int l);
void gen(enum f f, int l, int a);
void OutputCode();
%}


%union{
      struct{
            union{
                  int val;
                  char str;
                  float real;
            }data;
            //union DATA data;
            //float real;
            int kind;   //int 0, real 1, char 2
            char *str;
      }var;
      
}

%start Program
%token <var> IDENTIFIER CONSTANT FLOAT
%token <var> RELOP STR
%token COMMA SEMI DOT LPAREN RPAREN ASSIGN MINUS COLON
%token CONST VAR PROCEDURE _BEGIN_ END IF THEN ELSE ODD WHILE DO CALL READ WRITE FOR TO DOWNTO REPEAT UNTIL CHAR REAL STEP
%type <var> Factor Term Expr DoStep DowntoStep
%type <var> AssignStm
%left PLUS MINUS
%left TIMES DIVIDE
%nonassoc LOWER_THAN_ELSE 
%nonassoc ELSE 


%%
Program     :subProg DOT {
                  gen(OPR, 0, 0);
            }
            ;
subProg     :{
                  if(symtable_size() == 0) display_stack[++display_top] = 1;
                  else display_stack[++display_top] = symtable_size();  //写display表
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JMP, 0, 0);
            }
            DeclarePart 
            {
                  if(bkpchpos_top > -1){
                        Backpatch(bkpchpos[bkpchpos_top--], code_line);
                  }
                  if(display_stack[display_top] == 1){
                        gen(INT, 0, symtable.top + 3);
                  }
                  else{
                        gen(INT, 0, symtable.top - display_stack[display_top] + 3);
                  }
            }
            Statement 
            |{
                  if(symtable_size() == 0) display_stack[++display_top] = 1;
                  else display_stack[++display_top] = symtable_size();  //写display表
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JMP, 0, 0);
                  if(bkpchpos_top > -1){
                        Backpatch(bkpchpos[bkpchpos_top--], code_line);
                  }
                  if(display_stack[display_top] == 1){
                        gen(INT, 0, symtable.top + 3);
                  }
                  else{
                        gen(INT, 0, symtable.top - display_stack[display_top] + 3);
                  }
                  
            }
            Statement 
            ;

 /*常量、变量、过程声明部分*/
DeclarePart :ConstDec 
            |ConstDec VarDec 
            |ConstDec ProceDec 
            |ConstDec VarDec ProceDec 
            |VarDec ProceDec 
            |VarDec 
            |ProceDec 
            // | 
            ;
ConstDec    :CONST ConstDef SEMI 
            ; 
ConstDef    :ConstDef COMMA CDefine 
            |CDefine 
            ;
CDefine     :IDENTIFIER RELOP CONSTANT {
                  $1.data.val = $3.data.val; 
                  if(if_declared($1.str) == 0){ //常量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = $3.data.val; 
                        symtable_push($1.str, Const, tmp, false, 0, 0);
                  }
            }
            ;

VarDec      :VarDec VAR IdentiObj_var SEMI 
            |VarDec REAL IdentiObj_real SEMI 
            |VarDec CHAR IdentiObj_char SEMI 
            |VAR IdentiObj_var SEMI 
            |REAL IdentiObj_real SEMI 
            |CHAR IdentiObj_char SEMI 
            ;

IdentiObj_var    :IdentiObj_var COMMA IDENTIFIER {
                  if(if_declared($3.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($3.str, Int, tmp, false, 0, 0);
                  }
            }
            |IdentiObj_var COMMA IDENTIFIER LPAREN Expr COLON Expr RPAREN{
                  if($5.kind == 1 || $7.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if(if_declared($3.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($3.str, Int, tmp, true, $5.data.val, $7.data.val);
                  }
            }
            |IDENTIFIER {
                  if(if_declared($1.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($1.str, Int, tmp, false, 0, 0);
                  }
            }
            |IDENTIFIER LPAREN Expr COLON Expr RPAREN{
                  if($3.kind == 1 || $5.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if(if_declared($1.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($1.str, Int, tmp, true, $3.data.val, $5.data.val);
                  }
            }
            ;

IdentiObj_real   :IdentiObj_real COMMA IDENTIFIER {
                  if(if_declared($3.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($3.str, Real, tmp, false, 0, 0);
                  }
            }
            |IdentiObj_real COMMA IDENTIFIER LPAREN Expr COLON Expr RPAREN{
                  if($5.kind == 1 || $7.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if(if_declared($3.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($3.str, Real, tmp, true, $5.data.val, $7.data.val);
                  }
            }
            |IDENTIFIER {
                  if(if_declared($1.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($1.str, Real, tmp, false, 0, 0);
                  }
            }
            |IDENTIFIER LPAREN Expr COLON Expr RPAREN{
                  if($3.kind == 1 || $5.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if(if_declared($1.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($1.str, Real, tmp, true, $3.data.val, $5.data.val);
                  }
            }
            ;

IdentiObj_char   :IdentiObj_char COMMA IDENTIFIER {
                  if(if_declared($3.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($3.str, Char, tmp, false, 0, 0);
                  }
            }
            |IdentiObj_char COMMA IDENTIFIER LPAREN Expr COLON Expr RPAREN{
                  if($5.kind == 1 || $7.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if(if_declared($3.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($3.str, Char, tmp, true, $5.data.val, $7.data.val);
                  }
            }
            |IDENTIFIER {
                  if(if_declared($1.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($1.str, Char, tmp, false, 0, 0);
                  }
            }
            |IDENTIFIER LPAREN Expr COLON Expr RPAREN{
                  if($3.kind == 1 || $5.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if(if_declared($1.str) == 0){ //变量没有被定义,则可以入栈
                        DATA tmp;
                        tmp.val = -1; 
                        symtable_push($1.str, Char, tmp, true, $3.data.val, $5.data.val);
                  }
            }
            ;


ProceDec    :ProceHead subProg SEMI {
                  gen(OPR, 0, 0);
                  now_Level --;  //当前层数-1
                  symtable_pop();
                  addr = 2 + symtable_size();  //addr置为过程定义前的位置
            }
            |ProceDec ProceHead subProg SEMI {
                  gen(OPR, 0, 0);
                  now_Level --;  //当前层数-1
                  symtable_pop();
                  addr = 2 + symtable_size();  //addr置为过程定义前的位置
            }
            // | 
            ;
ProceHead   :PROCEDURE IDENTIFIER SEMI  {
                  addr = 3;
                  if(if_declared($2.str) == 0){ //过程名没有被定义,则可以入栈
                        if(findpro($2.str) == -1){
                              DATA tmp;
                              tmp.val = -2; 
                              symtable_push($2.str, Proc, tmp, false, 0, 0);  //入符号表栈
                        }
                        else{
                              printf("line %d error: Procedure '%s' has been declared!\n", row_num, $2.str);
                              exit(1);
                        }
                  }
                  now_Level ++;  //当前层数+1
            }
            ;


Statement   :AssignStm 
            |ComplexStm 
            |CondStm 
            |WhilelpStm 
            |ForStm
            |RepeatStm
            |CallStm 
            |ReadStm 
            |WriteStm 
            // | 
            ;
AssignStm   :IDENTIFIER ASSIGN Expr {
                  if(find_sign($1.str) == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n", row_num, $1.str);
                        exit(1);
                  }
                  int temp = find_sign($1.str);
                  if(temp == -1){
                        printf("line %d error: Cannot find the IDENTIFIER '%s'!\n", row_num, $1.str);
                        exit(1);
                  }
                  else{
                        if(symtable.index[temp].kind == Const){
                              printf("line %d error: Constant '%s' cannot be assigned!\n", row_num, $1.str);
                              exit(1);
                        }
                        if(symtable.index[temp].kind != Real && $3.kind != 1)
                              symtable.index[temp].data.val = $3.data.val;
                        if(symtable.index[temp].kind != Real && $3.kind == 1)
                              symtable.index[temp].data.val = (int)$3.data.real;
                        if(symtable.index[temp].kind == Real && $3.kind != 1)
                              symtable.index[temp].data.real = (float)$3.data.val;
                        if(symtable.index[temp].kind == Real && $3.kind == 1)
                              symtable.index[temp].data.real = $3.data.real;
                  }
                  if(symtable.index[temp].kind != Real){
                        if($3.kind == 1)
                              gen(R2I, 0, 0);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  if(symtable.index[temp].kind == Real){
                        if($3.kind != 1)
                              gen(I2R, 0, 0);
                        gen(STOF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  $$.data.val = temp;
            }
            |IDENTIFIER LPAREN Expr RPAREN ASSIGN Expr {
                  if(find_sign($1.str) == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n", row_num, $1.str);
                        exit(1);
                  }
                  if($3.kind == 1){
                        printf("line %d error: Array index need non real type.\n", row_num);
                        exit(1);
                  }
                  int temp = find_sign($1.str);
                  if(temp == -1){
                        printf("line %d error: Cannot find the IDENTIFIER '%s'!\n", row_num, $1.str);
                        exit(1);
                  }
                  else{
                        if($3.data.val > symtable.index[temp].array_up){
                              printf("line %d error: Array out of bounds.\n",row_num);
                              exit(1);
                        }
                        temp += $3.data.val - symtable.index[temp].array_low;
                        if(symtable.index[temp].kind != Real && $6.kind != 1)
                              symtable.index[temp].data.val = $6.data.val;
                        if(symtable.index[temp].kind != Real && $6.kind == 1)
                              symtable.index[temp].data.val = (int)$6.data.real;
                        if(symtable.index[temp].kind == Real && $6.kind != 1)
                              symtable.index[temp].data.real = (float)$6.data.val;
                        if(symtable.index[temp].kind == Real && $6.kind == 1)
                              symtable.index[temp].data.real = $6.data.real;
                  }
                  if(symtable.index[temp].kind != Real){
                        if($6.kind == 1)
                              gen(R2I, 0, 0);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  if(symtable.index[temp].kind == Real){
                        if($6.kind != 1)
                              gen(I2R, 0, 0);
                        gen(STOF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  $$.data.val = temp;
            }
            ;
ComplexStm  :_BEGIN_ Statemt END 
            ;
Statemt     :Statement SEMI 
            |Statemt Statement SEMI 
            // | 
            ;
CondStm     :IF Condition BeforeThen THEN Statement %prec LOWER_THAN_ELSE {
                  Backpatch(bkpchpos[bkpchpos_top--], code_line);
            }
            |IF Condition BeforeThen THEN Statement ELSE BeforeElseDo Statement{
                  Backpatch(bkpchpos[bkpchpos_top--], code_line);
            }
            ;
BeforeThen  :{
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JPC, 0, 0);
            }
            ;
BeforeElseDo:{
                  Backpatch(bkpchpos[bkpchpos_top--], code_line+1);  //回填条件错误跳转的地址
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JMP, 0, 0);
            }
            ;
Condition   :Expr RELOP Expr {
                  if($1.kind != 1 && $3.kind == 1)
                        gen(I2R, 0, 1);
                  else if($1.kind == 1 && $3.kind != 1)
                        gen(I2R, 0, 0);
                  if($1.kind != 1 && $3.kind != 1){
                        if(strcmp($2.str, "=") == 0) gen(OPR, 0, 8);
                        if(strcmp($2.str, "#") == 0) gen(OPR, 0, 9);
                        if(strcmp($2.str, "<") == 0) gen(OPR, 0, 10);
                        if(strcmp($2.str, ">=") == 0) gen(OPR, 0, 11);
                        if(strcmp($2.str, ">") == 0) gen(OPR, 0, 12);
                        if(strcmp($2.str, "<=") == 0) gen(OPR, 0, 13);
                  }
                  else{
                        if(strcmp($2.str, "=") == 0) gen(OPR, 1, 8);
                        if(strcmp($2.str, "#") == 0) gen(OPR, 1, 9);
                        if(strcmp($2.str, "<") == 0) gen(OPR, 1, 10);
                        if(strcmp($2.str, ">=") == 0) gen(OPR, 1, 11);
                        if(strcmp($2.str, ">") == 0) gen(OPR, 1, 12);
                        if(strcmp($2.str, "<=") == 0) gen(OPR, 1, 13);
                  }
            }
            |ODD Expr {
                  if($2.kind != 1)
                        gen(OPR, 0, 6);   
                  else{
                        printf("line %d error: Real type %s has no parity.\n", row_num, $2.str);
                        exit(1);
                  }
            }
            ;
Expr        :Expr PLUS Term {
                  if($1.kind != 1 && $3.kind != 1){
                        $$.data.val = $1.data.val + $3.data.val;
                        $$.kind = 0;
                        gen(OPR, 0, 2);
                  }
                  else if($1.kind == 1 && $3.kind == 1){
                        $$.data.real = $1.data.real + $3.data.real;
                        $$.kind = 1;
                        gen(OPR, 1, 2);
                  }
                  else if($1.kind != 1 && $3.kind == 1){
                        $$.data.real = (float)$1.data.val + $3.data.real;
                        $$.kind = 1;
                        gen(I2R, 0, 1);
                        gen(OPR, 1, 2);
                  }
                  else if($1.kind == 1 && $3.kind != 1){
                        $$.data.real = $1.data.real + (float)$3.data.val;
                        $$.kind = 1;
                        gen(I2R, 0, 0);
                        gen(OPR, 1, 2);
                  }
            }
            |Expr MINUS Term {
                  if($1.kind != 1 && $3.kind != 1){
                        $$.data.val = $1.data.val - $3.data.val;
                        $$.kind = 0;
                        gen(OPR, 0, 3);
                  }
                  else if($1.kind == 1 && $3.kind == 1){
                        $$.data.real = $1.data.real - $3.data.real;
                        $$.kind = 1;
                        gen(OPR, 1, 3);
                  }
                  else if($1.kind != 1 && $3.kind == 1){
                        $$.data.real = (float)$1.data.val - $3.data.real;
                        $$.kind = 1;
                        gen(I2R, 0, 1);
                        gen(OPR, 1, 3);
                  }
                  else if($1.kind == 1 && $3.kind != 1){
                        $$.data.real = $1.data.real - (float)$3.data.val;
                        $$.kind = 1;
                        gen(I2R, 0, 0);
                        gen(OPR, 1, 3);
                  }
            }
            |PLUS Term {
                  $$ = $2;
            }
            |MINUS Term {
                  $$ = $2;
                  if($2.kind != 1){
                        $$.data.val = -$2.data.val;
                        gen(OPR, 0, 1);
                  }
                  else if($2.kind == 1){
                        $$.data.real = -$2.data.real;
                        gen(OPR, 1, 1);
                  }
            }
            |Term {
                  $$ = $1;
            }
            ;
Term        :Term TIMES Factor {
                  if($1.kind != 1 && $3.kind != 1){
                        $$.data.val = $1.data.val * $3.data.val;
                        $$.kind = 0;
                        gen(OPR, 0, 4);
                  }
                  else if($1.kind == 1 && $3.kind == 1){
                        $$.data.real = $1.data.real * $3.data.real;
                        $$.kind = 1;
                        gen(OPR, 1, 4);
                  }
                  else if($1.kind != 1 && $3.kind == 1){
                        $$.data.real = (float)$1.data.val * $3.data.real;
                        $$.kind = 1;
                        gen(I2R, 0, 1);
                        gen(OPR, 1, 4);
                  }
                  else if($1.kind == 1 && $3.kind != 1){
                        $$.data.real = $1.data.real * (float)$3.data.val;
                        $$.kind = 1;
                        gen(I2R, 0, 0);
                        gen(OPR, 1, 4);
                  }
            }
            |Term DIVIDE Factor {
                  if($1.kind != 1 && $3.kind != 1){
                        $$.data.val = $1.data.val / $3.data.val;
                        $$.kind = 0;
                        gen(OPR, 0, 5);
                  }
                  else if($1.kind == 1 && $3.kind == 1){
                        $$.data.real = $1.data.real / $3.data.real;
                        $$.kind = 1;
                        gen(OPR, 1, 5);
                  }
                  else if($1.kind != 1 && $3.kind == 1){
                        $$.data.real = (float)$1.data.val / $3.data.real;
                        $$.kind = 1;
                        gen(I2R, 0, 1);
                        gen(OPR, 1, 5);
                  }
                  else if($1.kind == 1 && $3.kind != 1){
                        $$.data.real = $1.data.real / (float)$3.data.val;
                        $$.kind = 1;
                        gen(I2R, 0, 0);
                        gen(OPR, 1, 5);
                  }
            }
            |Factor {
                  $$ = $1;
            }
            ;
Factor      :IDENTIFIER {
                  if(find_sign($1.str) == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n", row_num, $1.str);
                        exit(1);
                  }
                  if(symtable.index[find_sign($1.str)].kind == Const){  //如果是常量
                        $$.data.val = symtable.index[find_sign($1.str)].data.val;
                        $$.kind = 0;
                        gen(LIT, 0, symtable.index[find_sign($1.str)].data.val);
                  }
                  if(symtable.index[find_sign($1.str)].kind == Int){  //如果是变量
                        $$.data.val = symtable.index[find_sign($1.str)].data.val;
                        $$.kind = 0;
                        gen(LODI, now_Level - symtable.index[find_sign($1.str)].level, symtable.index[find_sign($1.str)].addr);
                  }
                  if(symtable.index[find_sign($1.str)].kind == Real){  //如果是变量
                        $$.data.real = symtable.index[find_sign($1.str)].data.real;
                        $$.kind = 1;
                        gen(LODF, now_Level - symtable.index[find_sign($1.str)].level, symtable.index[find_sign($1.str)].addr);
                  }
                  if(symtable.index[find_sign($1.str)].kind == Char){  //如果是变量
                        $$.data.val = symtable.index[find_sign($1.str)].data.val;
                        $$.kind = 2;
                        gen(LODI, now_Level - symtable.index[find_sign($1.str)].level, symtable.index[find_sign($1.str)].addr);
                  }
            }
            |IDENTIFIER LPAREN Expr RPAREN{
                  int temp = find_sign($1.str);
                  if(temp == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n", row_num, $1.str);
                        exit(1);
                  }
                  if($3.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if($3.data.val > symtable.index[temp].array_up){
                        printf("line %d error: Array out of bounds\n",row_num);
                        exit(1);
                  }
                  temp += $3.data.val - symtable.index[temp].array_low;
                  if(symtable.index[temp].kind == Const){  //如果是常量
                        $$.data.val = symtable.index[temp].data.val;
                        $$.kind = 0;
                        gen(LIT, 0, symtable.index[temp].data.val);
                  }
                  if(symtable.index[temp].kind == Int){  //如果是变量
                        $$.data.val = symtable.index[temp].data.val;
                        $$.kind = 0;
                        gen(LODI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  if(symtable.index[temp].kind == Real){  //如果是变量
                        $$.data.real = symtable.index[temp].data.real;
                        $$.kind = 1;
                        gen(LODF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  if(symtable.index[temp].kind == Char){  //如果是变量
                        $$.data.val = symtable.index[temp].data.val;
                        $$.kind = 2;
                        gen(LODI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
            }
            |CONSTANT {
                  $$.data = $1.data;
                  $$.kind = 0;
                  gen(LIT, 0, $1.data.val);
            }
            |FLOAT {
                  $$.data = $1.data;
                  $$.kind = 1;
                  gen(LIT, 1, $1.data.val);
            }
            |STR {
                  $$.data = $1.data;
                  $$.kind = 2;
                  gen(LIT, 2, $1.data.val);
            }
            |LPAREN Expr RPAREN {
                  $$ = $2; 
            }
            ;
WhilelpStm  :WHILE BeforeCond Condition DO BeforeCondDo Statement {
                  gen(JMP, 0, whilepos[whiletop--]);
                  Backpatch(bkpchpos[bkpchpos_top--], code_line);
            }
            ;
BeforeCond  :{
                  whilepos[++whiletop] = code_line;
            }
            ;
BeforeCondDo:{
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JPC, 0, 0);                 
            }
            ;

ForStm      :FOR AssignStm TO {
                  forpos[++fortop] = code_line;
            }
            Expr {
                  int temp = $2.data.val;
                  if(symtable.index[temp].kind == Const){
                        printf("line %d error type const\n", row_num);
                        exit(1);
                  }
                  else if(symtable.index[temp].kind == Real)
                        gen(LODF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  else
                        gen(LODI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  if(symtable.index[temp].kind != Real && $5.kind == 1) 
                        gen(I2R, 0, 0);
                  if(symtable.index[temp].kind == Real && $5.kind != 1) 
                        gen(I2R, 0, 1);
                  if(symtable.index[temp].kind != Real && $5.kind != 1)
                        gen(OPR, 0, 11);
                  else
                        gen(OPR, 1, 11);
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JPC, 0, 0);
            }
            DoStep DO Statement {
                  int temp = $2.data.val;
                  if(symtable.index[temp].kind == Real){
                        gen(LODF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                        if($7.kind == 1){
                              gen(LIT, 1, $7.data.val);
                        }
                        else{
                              gen(LIT, 0, $7.data.val);
                              gen(I2R, 0, 0);
                        }
                        gen(OPR, 1, 2);
                        gen(STOF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  else{
                        gen(LODI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                        if($7.kind != 1){
                              gen(LIT, 0, $7.data.val);
                        }
                        else{
                              gen(LIT, 1, $7.data.val);
                              gen(R2I, 0, 0);
                        }
                        gen(OPR, 0, 2);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  gen(JMP, 0, forpos[fortop--]);
                  Backpatch(bkpchpos[bkpchpos_top--], code_line);
            }
            |FOR AssignStm DOWNTO {
                  forpos[++fortop] = code_line;
            }
            Expr {
                  int temp = $2.data.val;
                  if(symtable.index[temp].kind == Const){
                        printf("line %d error type const\n", row_num);
                        exit(1);
                  }
                  else if(symtable.index[temp].kind == Real)
                        gen(LODF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  else
                        gen(LODI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  if(symtable.index[temp].kind != Real && $5.kind == 1) 
                        gen(I2R, 0, 0);
                  if(symtable.index[temp].kind == Real && $5.kind != 1) 
                        gen(I2R, 0, 1);
                  if(symtable.index[temp].kind != Real && $5.kind != 1)
                        gen(OPR, 0, 13);
                  else
                        gen(OPR, 1, 13);
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JPC, 0, 0);
            }
            DowntoStep DO Statement {
                  int temp = $2.data.val;
                  if(symtable.index[temp].kind == Real){
                        gen(LODF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                        if($7.kind == 1){
                              gen(LIT, 1, $7.data.val);
                        }
                        else{
                              gen(LIT, 0, $7.data.val);
                              gen(I2R, 0, 0);
                        }
                        gen(OPR, 1, 2);
                        gen(STOF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  else{
                        gen(LODI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                        if($7.kind != 1){
                              gen(LIT, 0, $7.data.val);
                        }
                        else{
                              gen(LIT, 1, $7.data.val);
                              gen(R2I, 0, 0);
                        }
                        gen(OPR, 0, 2);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  gen(JMP, 0, forpos[fortop--]);
                  Backpatch(bkpchpos[bkpchpos_top--], code_line);
            }
            ;

DoStep      :STEP Expr {
                  $$ = $2;
            }
            | {
                  $$.data.val = 1;
                  $$.kind = 0;
            }
            ;

DowntoStep  :STEP Expr {
                  $$ = $2;
            }
            | {
                  $$.data.val = 1;
                  $$.kind = 0;
            }
            ;

RepeatStm     :REPEAT {
                  repeatpos[++repeattop]=code_line;
            }
            Statement UNTIL Condition {
                  bkpchpos[++bkpchpos_top] = code_line;  //填入回填栈等待回填
                  gen(JPC, 1, 0);
                  gen(JMP, 0, repeatpos[repeattop--]);
                  Backpatch(bkpchpos[bkpchpos_top--], code_line);
            }
            ;

CallStm     :CALL IDENTIFIER {
                  if(findpro($2.str) == -1){
                        printf("line %d error: Procedure '%s' not found!\n", row_num, $2.str);
                        exit(1);
                  }
                  else{
                        gen(CAL, now_Level - prostack[findpro($2.str)].l, prostack[findpro($2.str)].pos - 1);
                  }
            }
            ;


ReadStm     :READ LPAREN ReadId RPAREN
            ;

ReadId      :ReadId COMMA IDENTIFIER {
                  if(find_sign($3.str) == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n",row_num , $3.str);
                        exit(1);
                  }
                  if(symtable.index[find_sign($3.str)].kind == Int){
                        gen(OPR, 0, 16);
                        gen(STOI, now_Level - symtable.index[find_sign($3.str)].level, symtable.index[find_sign($3.str)].addr);
                  }
                  else if(symtable.index[find_sign($3.str)].kind == Real)
                  {
                        gen(OPR, 1, 16);
                        gen(STOF, now_Level - symtable.index[find_sign($3.str)].level, symtable.index[find_sign($3.str)].addr);
                  }
                  else if(symtable.index[find_sign($3.str)].kind == Char){
                        gen(OPR, 2, 16);
                        gen(STOI, now_Level - symtable.index[find_sign($3.str)].level, symtable.index[find_sign($3.str)].addr);
                  }
                  else{
                        printf("line %d: read type error.\n", row_num);
                        exit(1);
                  }
            }
            |ReadId COMMA IDENTIFIER LPAREN Expr RPAREN {
                  int temp = find_sign($3.str);
                  if(find_sign($3.str) == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n",row_num , $3.str);
                        exit(1);
                  }
                  if($5.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if($5.data.val > symtable.index[temp].array_up){
                        printf("line %d error: Array out of bounds\n",row_num);
                        exit(1);
                  }
                  temp += $5.data.val - symtable.index[temp].array_low;
                  if(symtable.index[temp].kind == Int){
                        gen(OPR, 0, 16);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  else if(symtable.index[temp].kind == Real)
                  {
                        gen(OPR, 1, 16);
                        gen(STOF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  else if(symtable.index[temp].kind == Char){
                        gen(OPR, 2, 16);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  
            }
            |IDENTIFIER {
                  if(find_sign($1.str) == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n",row_num , $1.str);
                        exit(1);
                  }
                  if(symtable.index[find_sign($1.str)].kind == Int){
                        gen(OPR, 0, 16);
                        gen(STOI, now_Level - symtable.index[find_sign($1.str)].level, symtable.index[find_sign($1.str)].addr);
                  }
                  else if(symtable.index[find_sign($1.str)].kind == Real)
                  {
                        gen(OPR, 1, 16);
                        gen(STOF, now_Level - symtable.index[find_sign($1.str)].level, symtable.index[find_sign($1.str)].addr);
                  }
                  else if(symtable.index[find_sign($1.str)].kind == Char){
                        gen(OPR, 2, 16);
                        gen(STOI, now_Level - symtable.index[find_sign($1.str)].level, symtable.index[find_sign($1.str)].addr);
                  }
                  else{
                        printf("line %d: read type error.\n", row_num);
                        exit(1);
                  }
            }
            |IDENTIFIER LPAREN Expr RPAREN {
                  int temp = find_sign($1.str);
                  if(find_sign($1.str) == -1){ //变量没有被定义
                        printf("line %d error: '%s' has not been declared!\n",row_num , $1.str);
                        exit(1);
                  }
                  if($3.kind == 1){
                        printf("line %d error: Array index need non real type.\n",row_num);
                        exit(1);
                  }
                  if($3.data.val > symtable.index[temp].array_up){
                        printf("line %d error: Array out of bounds\n",row_num);
                        exit(1);
                  }
                  temp += $3.data.val - symtable.index[temp].array_low;
                  if(symtable.index[temp].kind == Int){
                        gen(OPR, 0, 16);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  else if(symtable.index[temp].kind == Real)
                  {
                        gen(OPR, 1, 16);
                        gen(STOF, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  else if(symtable.index[temp].kind == Char){
                        gen(OPR, 2, 16);
                        gen(STOI, now_Level - symtable.index[temp].level, symtable.index[temp].addr);
                  }
                  
            }
            ;

WriteStm    :WRITE LPAREN ExprObj RPAREN {
                  //gen(OPR, 0, 14);
                  gen(OPR, 0, 15);
            }
            ;
ExprObj     :ExprObj COMMA Expr {
                  if($3.kind == 0)
                        gen(OPR, 0, 14);
                  if($3.kind == 1)
                        gen(OPR, 1, 14);
                  if($3.kind == 2)
                        gen(OPR, 2, 14);
            }
            |Expr {
                  if($1.kind == 0)
                        gen(OPR, 0, 14);
                  if($1.kind == 1)
                        gen(OPR, 1, 14);
                  if($1.kind == 2)
                        gen(OPR, 2, 14);
            }
            ;

%%
int main(){

      fp = fopen("pcode.txt", "w+");
      //symtable_init();
      init();

      yyparse();
      
      for(int i = 0; i < code_line; i++){
            fprintf(fp, "%s %d %d\n", fname[code[i].f], code[i].l, code[i].a);
      }

      return 0;
}

void init(){
      symtable.top=0;
      display_top=1;
      display_stack[display_top]=1;

      
}


int yyerror(char *s){
      printf("(%d,%d), %s\n", row_num, col_num, s);
      // fprintf(stderr,"%s\n",s);
      return 1;
}


void symtable_pop(){    //当前层所有符号出栈, display栈顶出栈
      int offset = display_stack[display_top] - 1;
      if(symtable.top == -1){
            printf("Overflow symtable pop size.\n");
            exit(1);
      }
      int i, j;
      for(i = symtable.top; i > offset; i--){
            symtable.index[symtable.top].name = NULL;
            symtable.index[symtable.top].kind = -1;
            symtable.index[symtable.top].level = -1;
            symtable.index[symtable.top].previous = -1;     
      }
      symtable.top = offset;
      symtable.index[symtable.top].previous = 0;
      //symtable.index[symtable.top].kind = 0;
      display_stack[display_top] = 0;  //display栈顶出栈
      display_top--;
      // return symtable.index[symtable.top --];
}


void symtable_push(char *id_name, int k, DATA v, bool if_array, int array_low, int array_up){ //标识符名字、类型、值
      int preoffset = symtable.top; //前一个符号在符号表中的位置
      symtable.top ++;
      symtable.index[symtable.top].name = id_name;
      symtable.index[symtable.top].kind = k;
      symtable.index[symtable.top].data = v;
      symtable.index[symtable.top].level = now_Level;
      symtable.index[symtable.top].previous = 0;
      symtable.index[symtable.top].if_array = if_array;
      symtable.index[symtable.top].array_low = array_low;
      symtable.index[symtable.top].array_up = array_up;
      if(k != Proc){  //当前为变量或常量
            if(symtable.top > 0){
                  symtable.index[preoffset].previous = symtable.top;
            }
            if(k != Const){
                  symtable.index[symtable.top].addr = addr++;
            }
            if(if_array){
                  for(int i = 0; i < array_up - array_low; i++){
                        symtable.top ++;
                        //symtable.index[symtable.top].name = strdup(' ');
                        symtable.index[symtable.top].kind = k;
                        symtable.index[symtable.top].data = v;
                        symtable.index[symtable.top].level = now_Level;
                        symtable.index[symtable.top].previous = symtable.top;
                        symtable.index[symtable.top].addr = addr++;
                  }
            }
      }
      if(k == Proc){  //当前为过程, 写入过程栈, 记录该过程开始的code_line
            prostktop ++;
            prostack[prostktop].proname = strdup(id_name);
            prostack[prostktop].pos = code_line + 1;
            prostack[prostktop].l = now_Level;
      }

}


int if_declared(char *sign_name){   //标识符是否被定义过
      int nowtable = display_stack[display_top];
      // printf("nowtable: %d  symtable.top: %d\n", nowtable, symtable.top);
      while(nowtable <= symtable.top){
            //变量名和过程名不能重名
            if(strcmp(symtable.index[nowtable].name, sign_name) == 0){
                  printf("Error! '%s' has been declared!\n", sign_name);
                  exit(1);
            }
            if(symtable.index[nowtable].previous == 0){
                  break;
            }
            nowtable ++;
      }
      return 0;
}


int find_sign(char *sign_name){  //查找标识符在符号栈中的位置
      int nowdistop = display_top;  //当前寻找的display顶
      int symbolpos;  //去符号栈中找的位置
      while(nowdistop > 0){  //display没有找完
            symbolpos = display_stack[nowdistop];
            while(symbolpos <= symtable.top){
                  if(strcmp(sign_name, symtable.index[symbolpos].name) == 0 && symtable.index[symbolpos].kind != Proc){  //符号栈中此位置的变量和查找变量相同
                        return symbolpos;  //返回该符号位置
                  }
                  if(symtable.index[symbolpos].previous == 0){  //查找到当前过程底部
                        break;
                  }
                  symbolpos ++;
            }
            nowdistop --;  //查找上一层
      }
      return -1;  //没找到该符号
}

int findpro(char *pname){
      int i;
      for(i = 0; i <= prostktop; i++){
            if(strcmp(pname, prostack[i].proname) == 0){
                  return i;
            }
      }
      return -1;
}


int symtable_size(){
      return symtable.top;
}


void gen(enum f f, int l, int a){  //生成类pcode代码放到code结构体数组中
      code[code_line].f = f;
      code[code_line].l = l;
      code[code_line].a = a;
      code_line ++;
}

void Backpatch(int p, int l){  //回填函数, 参数为回填位置和回填内容
      code[p].a = l;  //将第p条code的a域改为l
}

