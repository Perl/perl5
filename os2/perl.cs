(-W1 -Od -Olt -DDEBUGGING -Gt2048
array.c cmd.c cons.c consarg.c doarg.c doio.c dolist.c dump.c form.c
hash.c perl.c perly.c regcomp.c regexec.c stab.c str.c util.c
)
(-W1 -Od -Olt -B2C2L -B3C3L -DDEBUGGING eval.c{evalargs.xc} toke.c)
(-W1 -Od -Olt os2.c popen.c mktemp.c director.c suffix.c)

setargv.obj
perl.def
perl.bad
perl.exe

-AL -LB -S0x9000
