package Dev::Null;
# $Id: /mirror/googlecode/test-more/t/lib/Dev/Null.pm 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

sub TIEHANDLE { bless {} }
sub PRINT { 1 }

1;
