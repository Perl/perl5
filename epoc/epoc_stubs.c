/*
 *    Copyright (c) 1999 Olaf Flebbe o.flebbe@gmx.de
 *    
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

int getgid() {return 0;}
int getegid() {return 0;}
int geteuid() {return 0;}
int getuid() {return 0;}
int setgid() {return -1;}
int setuid() {return -1;}

int Perl_my_popen( int a, int b) {
	 return 0;
}
int Perl_my_pclose( int a) {
	 return 0;
}

kill() {}
signal() {}

void execv() {}
void execvp() {}
void do_spawn() {}
void do_aspawn() {}
void Perl_do_exec() {}

