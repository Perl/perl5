# XXX Configure test needed.
# Some Linux releases like to hide their <nlist.h>
no strict 'vars';
$self->{CCFLAGS} = $Config{ccflags} . ' -I/usr/include/libelf'
	if -f "/usr/include/libelf/nlist.h";
1;
