echo ': work around botch in SunOS 4.0.1 and 4.0.2'	>>../perl.h
echo '#ifndef fputs'					>>../perl.h
echo '#define fputs(str,fp) fprintf(fp,"%s",str)'	>>../perl.h
echo '#endif'						>>../perl.h
