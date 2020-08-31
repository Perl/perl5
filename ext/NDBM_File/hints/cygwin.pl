# uses GDBM ndbm compatibility feature
no strict 'vars';
$self->{LIBS} = ['-lgdbm -lgdbm_compat'];
