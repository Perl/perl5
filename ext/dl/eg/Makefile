CC = /vol/apps/lucid-3.1/lcc

all: 	main test test1
main:	main.c
	$(CC) -g -o main main.c -ldl

test.o:	test.c
	$(CC) -g -pic -c test.c

test:	test.o
	ld -o test -assert pure-text test.o

test1.o:	test1.c
	$(CC) -g -pic -c test1.c

test1:	test1.o
	ld -o test1 -assert pure-text test1.o

clean:
	/bin/rm -f *.o test test1 main
