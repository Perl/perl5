yacc='/usr/bin/yacc -Sm11000'
libswanted=`echo $libswanted | sed 's/ x / /'`
i_varargs=undef
ccflags="$ccflags -U M_XENIX"
