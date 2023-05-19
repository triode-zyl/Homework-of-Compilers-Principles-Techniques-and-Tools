%{
#include<stdio.h>
#include"test.tab.h"
#include"tree.h"
int num_lines=1,num_chars=1;
/*
#define KEY 1
#define IDENTIFIER 2
#define CONSTANT 3
#define OPERATOR 4
#define DELIMITER 5
#define OTHER 6*/
%}
/*正规定义*/
/*enter [\n\r]*/
/*tab [\t]*/
/*space [ ]*/
key if|then|while|do|read|write|call|begin|end|const|var|procedure|odd|for|to|step|repeat|until|char|real
letter [A-Za-z]
digit [0-9]
integer [+-]?{digit}+
float [+-]?{digit}+(\.{digit}+)?((E|e)[+-]?{digit}+)?
string \"[^\n^\"]+\"
id ({letter}|{digit}|_)*
array {id}\({digit}+":"{digit}+\)
operator "#"|\<|\>|"<="|">="|"="
/*delimiter ":"|"."|","|";"|\[|\]|\"|\'|\{|\}|\(|\)*/
/*illegal [`~!@#_$%&*<>?~！@#￥%……&*（）——|{}【】《》‘；：”“’。，、？/\^]*/
other [^ \n\r\t{key}{id}{integer}{float}{string}{operator}]
/*({illegal}|{digit})*{id}**/
/*%s COMMENT*/
/*%s COMMENT2*/
%%
 /*翻译部分*/

"\n" {num_lines++;num_chars=1;}
[ ] {num_chars++;}
"\t" {num_chars+=4;}
if {printf("%d,%d:%s IF\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("IF");return IF;}
then {printf("%d,%d:%s THEN\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("THEN");return THEN ;}
while {printf("%d,%d:%s WHILE\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("WHILE");return WHILE;}
do {printf("%d,%d:%s DO\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("DO");return DO;}
read {printf("%d,%d:%s READ\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("READ");return READ;}
write {printf("%d,%d:%s WRITE\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("WRITE");return WRITE;}
call {printf("%d,%d:%s CALL\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("CALL");return CALL;}
begin {printf("%d,%d:%s BEGIN_\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("BEGIN");return BEGIN_;}
end {printf("%d,%d:%s END\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("END");return END;}
const {printf("%d,%d:%s CONST\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("CONST");return CONST;}
var {printf("%d,%d:%s VAR\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("VAR");return VAR;}
procedure {printf("%d,%d:%s PROCEDURE\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("PROCEDURE");return PROCEDURE;}
odd {printf("%d,%d:%s ODD\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("ODD");return ODD;}
for {printf("%d,%d:%s FOR\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("FOR");return FOR;}
to {printf("%d,%d:%s TO\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("TO");return TO;}
step {printf("%d,%d:%s STEP\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("STEP");return STEP;}
repeat {printf("%d,%d:%s REPEAT\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("REPEAT");return REPEAT;}
until {printf("%d,%d:%s UNTIL\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("UNTIL");return UNTIL;}
char {printf("%d,%d:%s CHAR\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("CHAR");return CHAR;}
real {printf("%d,%d:%s REAL\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode("REAL");return REAL;}

{integer} {printf("%d,%d:%s INTEGER\n",num_lines,num_chars,yytext);
			num_chars+=yyleng;
			if(yyleng>10) 
				fprintf(yyout,"Warning: integer %s\'s length is longer than 10.\n",yytext);
			yylval.token_p=newNode(yytext);
			return INTEGER;}
{id} 	{printf("%d,%d:%s IDENTIFIER\n",num_lines,num_chars,yytext);
		num_chars+=yyleng;
		if(yyleng>10) 
			fprintf(yyout,"Warning: identifier %s\'s length is longer than 10.\n",yytext);
		if(!('a'<=yytext[0]&&yytext[0]<='z'||'A'<=yytext[0]&&yytext[0]<='Z'))
			fprintf(yyout,"Invalid identifier %s.\n",yytext);
		yylval.token_p=newNode(yytext);
		return IDENTIFIER;}
{float} {printf("%d,%d:%s FLOAT\n",num_lines,num_chars,yytext);
	num_chars+=yyleng;
	if(yyleng>15) 
		fprintf(yyout,"Warning: float %s\'s length is longer than 15.\n",yytext);
	yylval.token_p=newNode(yytext);
	return FLOAT;}
{string} {printf("%d,%d:%s STRING\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return STRING;}
\+|\- {printf("%d,%d:%s ADDSUB\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return ADDSUB;}
\*|\/ {printf("%d,%d:%s MULTIDIV\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return MULTIDIV;}
":=" {printf("%d,%d:%s EQUAL\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return EQUAL;}
"." {printf("%d,%d:%s DOT\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return DOT;}
"," {printf("%d,%d:%s COMMA\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return COMMA;}
";" {printf("%d,%d:%s SEM\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return SEM;}
":" {printf("%d,%d:%s COLON\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return COLON;}
\( {printf("%d,%d:%s LP\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return LP;}
\) {printf("%d,%d:%s RP\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return RP;}
{operator} {printf("%d,%d:%s OPERATOR\n",num_lines,num_chars,yytext);num_chars+=yyleng;yylval.token_p=newNode(yytext);return OPERATOR;}
{other} {printf("%d,%d:%s OTHER\n",num_lines,num_chars,yytext);num_chars+=yyleng;fprintf(yyout,"Invalid character %s.\n",yytext);}
 /*<INITIAL>\" {num_chars+=yyleng;return (DELIMITER);begin COMMENT;}
<COMMENT>{string} {num_chars+=yyleng;return (CONSTANT);begin COMMENT2;}
<COMMENT2>\" {num_chars+=yyleng;return (DELIMITER);}*/
%%
/*辅助函数*/
int yywrap (){
  return 1;
}
/*
void writeout(int c)
{
	switch(c)
	{
		case KEY:
			fprintf(yyout,"%s : K, (%d, %d)\n",yytext,num_lines,num_chars-yyleng);break;
		case IDENTIFIER:
			fprintf(yyout,"%s : I, (%d, %d)\n",yytext,num_lines,num_chars-yyleng);break;
		case CONSTANT:
			fprintf(yyout,"%s : C, (%d, %d)\n",yytext,num_lines,num_chars-yyleng);break;
		case OPERATOR:
			fprintf(yyout,"%s : O, (%d, %d)\n",yytext,num_lines,num_chars-yyleng);break;
		case DELIMITER:
			fprintf(yyout,"%s : D, (%d, %d)\n",yytext,num_lines,num_chars-yyleng);break;
		case OTHER:
			fprintf(yyout,"%s : T, (%d, %d)\n",yytext,num_lines,num_chars-yyleng);break;
	}
}*/
/*
int main(int argc, char *argv[])
{
	FILE * fIn;			//PL0文件的指针
	switch(argc)
	{
	case 2: 			//打开指定文件
		if ((fIn = fopen(argv[1],"r")) == NULL) {
	            printf("File %s is not found.\n",argv[1]);
	            exit(1);
	        }
	        else	yyin=fIn;
		break;
    case 3:
        if ((fIn = fopen(argv[1],"r")) == NULL) {
	            printf("File %s is not found.\n",argv[1]);
	            exit(1);
	        }
	        else	yyin=fIn;
        yyout=fopen(argv[2], "w");
		break;
	default:
		printf("useage:flex [filename]\n");
		exit(1);
	}
	int c;
    while(c=yylex())
		writeout(c);
	
	fclose(fIn);
    if(argc==3) fclose(yyout);
	return 0;
}*/