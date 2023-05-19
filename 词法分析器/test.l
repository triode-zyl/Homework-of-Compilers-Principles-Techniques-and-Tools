%{
#include<stdio.h>
int num_lines=1,num_chars=1;
#define KEY 1
#define IDENTIFIER 2
#define CONSTANT 3
#define OPERATOR 4
#define DELIMITER 5
#define OTHER 6
%}
/*正规定义*/
/*enter [\n\r]*/
/*tab [\t]*/
/*space [ ]*/
key if|then|while|do|read|write|call|begin|end|const|var|procedure|odd|for|to|step|repeat|until|string|float
letter [A-Za-z]
digit [0-9]
integer [+-]?{digit}+
float [+-]?{digit}+(\.{digit}+)?((E|e)[+-]?{digit}+)?
string \"[^\n^\"]+\"
id ({letter}|{digit}|_)*
array {id}\({digit}+":"{digit}+\)
operator \+|\-|\*|\/|\\|\<|\>|"<="|">="|"=="|"!="|":="|"="
delimiter ":"|"."|","|";"|\[|\]|\"|\'|\{|\}|\(|\)
/*illegal [`~!@#_$%&*<>?~！@#￥%……&*（）——|{}【】《》‘；：”“’。，、？/\^]*/
other [^ \n\r\t{key}{id}{integer}{float}{string}{operator}{delimiter}]
/*({illegal}|{digit})*{id}**/
/*%s COMMENT*/
/*%s COMMENT2*/
%%
 /*翻译部分*/

"\n"|"\r" {num_lines++;num_chars=1;}
[ ] {num_chars++;}
"\t" {num_chars+=4;}
{key} {num_chars+=yyleng;return (KEY);}
{id} {num_chars+=yyleng;if(yyleng>10) fprintf(yyout,"Warning: identifier length is longer than 10.\n");return (IDENTIFIER);}
{integer} {num_chars+=yyleng;if(yyleng>10) fprintf(yyout,"Warning: integer length is longer than 10.\n");return (CONSTANT);}
{float} {num_chars+=yyleng;if(yyleng>15) fprintf(yyout,"Warning: float length is longer than 15.\n");return (CONSTANT);}
{string} {num_chars+=yyleng;return (CONSTANT);}
{operator} {num_chars+=yyleng;return (OPERATOR);}
{delimiter} {num_chars+=yyleng;return (DELIMITER);}
{other} {num_chars+=yyleng;return(OTHER);}
 /*<INITIAL>\" {num_chars+=yyleng;return (DELIMITER);begin COMMENT;}
<COMMENT>{string} {num_chars+=yyleng;return (CONSTANT);begin COMMENT2;}
<COMMENT2>\" {num_chars+=yyleng;return (DELIMITER);}*/
%%
/*辅助函数*/
int yywrap (){
  return 1;
}
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
}
int main(int argc, char *argv[])
{
	FILE * fIn;			//PL0文件的指针
	switch(argc)
	{
	/*case 1: 			//打开缺省文件		
		fIn=fopen(“test.frag”,“r”);	
		if(fIn == NULL){
			printf("default file is not found\n");
			exit(1);
		}
		else	yyin = fIn;
		break;		*/
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
}