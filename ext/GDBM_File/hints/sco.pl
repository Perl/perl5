# SCO OSR5 needs to link with libc.so again to have C<fsync> defined
no strict 'vars';
$self->{LIBS} = ['-lgdbm -lc'];
