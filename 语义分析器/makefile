result : main.l main.y
	flex main.l
	bison -d main.y
	gcc main.tab.c lex.yy.c -o main
	gcc interpret.c -o interpret
clean : main.tab.c main.tab.h lex.yy.c main interpret
	rm -rf main.tab.c main.tab.h lex.yy.c main interpret