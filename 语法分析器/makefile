result : main.y main.l tree.h
	bison -d main.y
	flex main.l
	gcc main.tab.c tree.c -o main
clean : lex.yy.c main.tab.c main.tab.h main
	rm -rf lex.yy.c main.tab.c main.tab.h main