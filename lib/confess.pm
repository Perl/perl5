package confess;
require Carp;
*Carp::shortmess = \&Carp::longmess;
1;
__END__
