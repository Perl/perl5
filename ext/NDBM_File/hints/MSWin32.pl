# uses GDBM dbm compatibility feature
no strict 'vars';
$self->{LIBS} = ['-lgdbm_compat -lgdbm'];
