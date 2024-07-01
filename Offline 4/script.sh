yacc -d -y 1805117.y
g++ -w -c -o y.o y.tab.c
flex 1805117.l
g++ -w -c -o l.o lex.yy.c
g++ 1805117_symbolInfo.cpp 1805117_scopeTable.cpp 1805117_symbolTable.cpp -c
g++ 1805117_symbolInfo.o 1805117_scopeTable.o 1805117_symbolTable.o y.o l.o -lfl
echo "done"
./a.out test.c