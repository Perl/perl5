# If this doesn't work, try specifying 'none' for hints.
d_castneg=undef
libswanted=`echo $libswanted | sed -e 's/socket /socket seq /'`
