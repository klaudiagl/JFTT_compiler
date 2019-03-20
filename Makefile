all:
	bison -d -v -t -b imp imp.y
	flex -o lex.yy.c imp.flex 
	gcc lex.yy.c imp.tab.c -lfl -o kompilator
destroy:
	rm imp.output imp.tab.c imp.tab.h kompilator lex.yy.c