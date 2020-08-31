#  Try to work around "bad free" messages.  See note in ODBM_File.xs.
#   Andy Dougherty  <doughera@lafayette.edu>
#   Sun Sep  8 12:57:52 EDT 1996
no strict 'vars';
$self->{CCFLAGS} = $Config{ccflags} . ' -DDBM_BUG_DUPLICATE_FREE' ;
