%{

#include <string.h>
#include <stdlib.h>
#include "main.tab.h"


#define maxsize 50
int row_num = 1, col_num = 1;  //行数和列数

%}


keyword if|then|while|do|read|write|call|begin|end|const|var|procedure|odd|for|to|downto|step|repeat|until|char|real
identifier [A-Za-z][A-Za-z0-9_]*
constant [+-]?[0-9]+
float [+-]?[0-9]+(\.[0-9]+)?((E|e)[+-]?[0-9]+)?
operator "#"|\<|\>|"<="|">="|"="
string \"[^\n^\"]+\"|\'[^\n^\']+\'
other [^ \n\r\t{keyword}{identifier}{constant}{operator}{float}{string}]

%%
\n {++row_num; col_num=1;}  
[ ] {++col_num;}
\t {col_num+=4;}

if {col_num+=yyleng;return IF;}
then {col_num+=yyleng;return THEN ;}
while {col_num+=yyleng;return WHILE;}
do {col_num+=yyleng;return DO;}
read {col_num+=yyleng;return READ;}
write {col_num+=yyleng;return WRITE;}
call {col_num+=yyleng;return CALL;}
begin {col_num+=yyleng;return _BEGIN_;}
end {col_num+=yyleng;return END;}
const {col_num+=yyleng;return CONST;}
var {col_num+=yyleng;return VAR;}
procedure {col_num+=yyleng;return PROCEDURE;}
odd {col_num+=yyleng;return ODD;}
for {col_num+=yyleng;return FOR;}
downto {col_num+=yyleng;return DOWNTO;}
to {col_num+=yyleng;return TO;}
step {col_num+=yyleng;return STEP;}
repeat {col_num+=yyleng;return REPEAT;}
until {col_num+=yyleng;return UNTIL;}
char {col_num+=yyleng;return CHAR;}
real {col_num+=yyleng;return REAL;}

{identifier} {
	if(yyleng > 10){
		printf("line %d row %d: error: expected a shorter IDENTIFIER!\n",row_num,col_num);
		exit(1);
	}
	col_num += yyleng;
	yylval.var.str = strdup(yytext);
	
	return IDENTIFIER;
}  
{constant} {
	if(yyleng > 14){
		printf("line %d row %d: error: expected a shorter CONSTANT!\n",row_num,col_num);
		exit(1);
	}
	col_num += yyleng;
	//yylval.val = atoi(yytext);
	yylval.var.data.val = atoi(yytext);
	yylval.var.kind=0;
	return CONSTANT;
}
{float} {
	if(yyleng > 14){
		printf("line %d row %d: error: expected a shorter FLOAT!\n",row_num,col_num);
		exit(1);
	}
	col_num += yyleng;
	//yylval.val = atof(yytext);
	yylval.var.data.real = atof(yytext);
	yylval.var.kind=1;
	return FLOAT;
}
{string} {
	if(yyleng != 3){
		printf("line %d row %d: error: type CHAR only support one character!\n",row_num,col_num);
		exit(1);
	}
	col_num += yyleng;
	yylval.var.data.val = yytext[1];
	yylval.var.kind=2;
	return STR;
}
{operator} {col_num+=yyleng;yylval.var.str=strdup(yytext);return RELOP;}
\+ {col_num+=yyleng;return PLUS;}
\- {col_num+=yyleng;return MINUS;}
\* {col_num+=yyleng;return TIMES;}
\/ {col_num+=yyleng;return DIVIDE;}
":=" {col_num+=yyleng;return ASSIGN;}
"." {col_num+=yyleng;return DOT;}
"," {col_num+=yyleng;return COMMA;}
":" {col_num+=yyleng;return COLON;}
";" {col_num+=yyleng;return SEMI;}
\( {col_num+=yyleng;return LPAREN;}
\) {col_num+=yyleng;return RPAREN;}


{other} {
	printf("line %d row %d: error: invalid character %s\n",row_num,col_num,yytext);
	exit(1);
	col_num += yyleng;
}

%%

int yywrap(){
	return 1;
}